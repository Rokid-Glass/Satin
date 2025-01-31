//
//  Geometry.swift
//  Satin
//
//  Created by Reza Ali on 7/23/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Combine
import Metal
import ModelIO
import QuartzCore
import SatinCore
import simd

open class Geometry: Codable {
    public var id: String = UUID().uuidString

    public var primitiveType: MTLPrimitiveType = .triangle {
        didSet {
            if primitiveType != oldValue, primitiveType != .triangle {
                if let bvh = _bvh {
                    print("changing primitive type from geometry")
                    freeBVH(bvh)
                }
                _bvh = nil
            }
        }
    }

    public var windingOrder: MTLWinding = .counterClockwise
    public var indexType: MTLIndexType = .uint32

    public let publisher = PassthroughSubject<Geometry, Never>()

    public var vertexData: [Vertex] = [] {
        didSet {
            publisher.send(self)
            _updateVertexBuffer = true
        }
    }

    public var indexData: [UInt32] = [] {
        didSet {
            publisher.send(self)
            _updateIndexBuffer = true
        }
    }

    public var bvh: BVH? {
        if _updateBVH, primitiveType == .triangle {
            setupBVH()
        }
        return _bvh
    }

    public var context: Context? {
        didSet {
            setup()
        }
    }

    var _updateVertexBuffer = true {
        didSet {
            if _updateVertexBuffer {
                _updateBounds = true
            }
        }
    }

    var _updateIndexBuffer = true {
        didSet {
            if _updateIndexBuffer {
                _updateBounds = true
            }
        }
    }

    var _updateBVH = true
    var _bvh: BVH?

    var _updateBounds = true {
        didSet {
            if _updateBounds {
                _updateBVH = true
            }
        }
    }

    var _bounds = createBounds()
    public var bounds: Bounds {
        if _updateBounds {
            _bounds = computeBounds()
            _updateBounds = false
        }
        return _bounds
    }

    public private(set) var vertexBuffers: [VertexBufferIndex: MTLBuffer] = [:]
    public var vertexBuffer: MTLBuffer? {
        didSet {
            if let vertexBuffer = vertexBuffer {
                vertexBuffers[VertexBufferIndex.Vertices] = vertexBuffer
            } else {
                vertexBuffers.removeValue(forKey: VertexBufferIndex.Vertices)
            }
        }
    }

    public var indexBuffer: MTLBuffer?

    public init() {}

    public init(_ geometryData: inout GeometryData) {
        setFrom(&geometryData)
    }

    public init(primitiveType: MTLPrimitiveType, windingOrder: MTLWinding = .counterClockwise, indexType: MTLIndexType = .uint32) {
        self.primitiveType = primitiveType
        self.windingOrder = windingOrder
        self.indexType = indexType
    }

    // MARK: - Codable

    public enum CodingKeys: String, CodingKey {
        case id
        case primitiveType
        case windingOrder
        case indexType
        case vertexData
        case indexData
    }

    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        primitiveType = try values.decode(MTLPrimitiveType.self, forKey: .primitiveType)
        windingOrder = try values.decode(MTLWinding.self, forKey: .windingOrder)
        indexType = try values.decode(MTLIndexType.self, forKey: .indexType)
        vertexData = try values.decode([Vertex].self, forKey: .vertexData)
        indexData = try values.decode([UInt32].self, forKey: .indexData)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(primitiveType, forKey: .primitiveType)
        try container.encode(windingOrder, forKey: .windingOrder)
        try container.encode(indexType, forKey: .indexType)
        try container.encode(vertexData, forKey: .vertexData)
        try container.encode(indexData, forKey: .indexData)
    }

    func setup() {
        setupVertexBuffer()
        setupIndexBuffer()
    }

    public func update() {
        if _updateVertexBuffer {
            setupVertexBuffer()
        }
        if _updateIndexBuffer {
            setupIndexBuffer()
        }
    }

    func setupVertexBuffer() {
        guard _updateVertexBuffer, let context = context else { return }
        let device = context.device
        if !vertexData.isEmpty {
            let stride = MemoryLayout<Vertex>.stride
            let verticesSize = vertexData.count * stride
            if let vertexBuffer = vertexBuffer, vertexBuffer.length == verticesSize {
                vertexBuffer.contents().copyMemory(from: &vertexData, byteCount: verticesSize)
            } else {
                vertexBuffer = device.makeBuffer(bytes: vertexData, length: verticesSize, options: [])
                vertexBuffer?.label = "Vertices"
            }
        } else {
            vertexBuffer = nil
        }
        _updateVertexBuffer = false
    }

    func setupIndexBuffer() {
        guard _updateIndexBuffer, let context = context else { return }
        let device = context.device
        if !indexData.isEmpty {
            let indicesSize = indexData.count * MemoryLayout.size(ofValue: indexData[0])
            indexBuffer = device.makeBuffer(bytes: indexData, length: indicesSize, options: [])
            indexBuffer?.label = "Indices"
        } else {
            indexBuffer = nil
        }
        _updateIndexBuffer = false
    }

    func setupBVH() {
        _bvh = createBVH(getGeometryData(), false)
        _updateBVH = false
    }

    public func setFrom(_ geometryData: inout GeometryData) {
        let vertexCount = Int(geometryData.vertexCount)
        if vertexCount > 0, let data = geometryData.vertexData {
            vertexData = Array(UnsafeBufferPointer(start: data, count: vertexCount))
        } else {
            vertexData = []
        }

        let indexCount = Int(geometryData.indexCount) * 3
        if indexCount > 0, let data = geometryData.indexData {
            data.withMemoryRebound(to: UInt32.self, capacity: indexCount) { ptr in
                indexData = Array(UnsafeBufferPointer(start: ptr, count: indexCount))
            }
        } else {
            indexData = []
        }
    }

    public func getGeometryData() -> GeometryData {
        var data = GeometryData()
        data.vertexCount = Int32(vertexData.count)
        data.indexCount = Int32(indexData.count / 3)

        vertexData.withUnsafeMutableBufferPointer { vtxPtr in
            data.vertexData = vtxPtr.baseAddress!
        }

        indexData.withUnsafeMutableBufferPointer { indPtr in
            let raw = UnsafeRawBufferPointer(indPtr)
            let ptr = raw.bindMemory(to: TriangleIndices.self)
            data.indexData = UnsafeMutablePointer(mutating: ptr.baseAddress!)
        }

        return data
    }

    public func unroll() {
        var data = getGeometryData()
        var unrolled = GeometryData()
        unrollGeometryData(&unrolled, &data)
        setFrom(&unrolled)
        freeGeometryData(&unrolled)
    }

    public func computeNormals() {
        var data = getGeometryData()
        computeNormalsOfGeometryData(&data)
    }

    public func setBuffer(_ buffer: MTLBuffer?, type: VertexBufferIndex) {
        vertexBuffers[type] = buffer
    }

    public func transform(_ matrix: simd_float4x4) {
        transformVertices(&vertexData, Int32(vertexData.count), matrix)
    }

    public func intersects(ray: Ray) -> Bool {
        return rayBoundsIntersect(ray, bounds)
    }

    public func intersect(ray: Ray, intersections: inout [IntersectionResult]) {
        if let bvh = bvh {
            bvh.intersect(ray: ray, intersections: &intersections)
        }
    }

    func computeBounds() -> Bounds {
        if let bvh = bvh, let node = bvh.getNode(index: 0) {
            return node.aabb
        }
        return computeBoundsFromVertices(&vertexData, Int32(vertexData.count))
    }

    deinit {
        indexData = []
        vertexData = []
        vertexBuffer = nil
        indexBuffer = nil
        if let bvh = _bvh {
            freeBVH(bvh)
            self._bvh = nil
        }
        vertexBuffers.removeAll()
    }
}

extension Geometry: Equatable {
    public static func == (lhs: Geometry, rhs: Geometry) -> Bool {
        return lhs === rhs
    }
}

extension Geometry: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self).hashValue)
    }
}
