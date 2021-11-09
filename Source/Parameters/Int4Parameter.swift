//
//  Int4Parameter.swift
//  Satin
//
//  Created by Reza Ali on 2/10/20.
//  Copyright © 2020 Reza Ali. All rights reserved.
//

import Foundation
import simd

open class Int4Parameter: NSObject, Parameter {
    public static var type = ParameterType.int4
    public var controlType: ControlType
    public let label: String
    public var string: String { return "int4" }
    public var size: Int { return MemoryLayout<simd_int4>.size }
    public var stride: Int { return MemoryLayout<simd_int4>.stride }
    public var alignment: Int { return MemoryLayout<simd_int4>.alignment }
    public var count: Int { return 4 }
    public var actions: [(simd_int4) -> Void] = []
    
    public subscript<Int32>(index: Int) -> Int32 {
        get {
            return value[index % count] as! Int32
        }
        set {
            value[index % count] = newValue as! Swift.Int32
        }
    }
    
    public func dataType<Int32>() -> Int32.Type {
        return Int32.self
    }
    
    var observers: [NSKeyValueObservation] = []
    
    @objc public dynamic var x: Int32
    @objc public dynamic var y: Int32
    @objc public dynamic var z: Int32
    @objc public dynamic var w: Int32
    
    @objc public dynamic var minX: Int32
    @objc public dynamic var maxX: Int32
    
    @objc public dynamic var minY: Int32
    @objc public dynamic var maxY: Int32
    
    @objc public dynamic var minZ: Int32
    @objc public dynamic var maxZ: Int32
    
    @objc public dynamic var minW: Int32
    @objc public dynamic var maxW: Int32
    
    public var value: simd_int4 {
        get {
            return simd_make_int4(x, y, z, w)
        }
        set(newValue) {
            x = newValue.x
            y = newValue.y
            z = newValue.z
            w = newValue.w
        }
    }
    
    public var min: simd_int4 {
        get {
            return simd_make_int4(minX, minY, minZ, minW)
        }
        set(newValue) {
            minX = newValue.x
            minY = newValue.y
            minZ = newValue.z
            minW = newValue.w
        }
    }
    
    public var max: simd_int4 {
        get {
            return simd_make_int4(maxX, maxY, maxZ, maxW)
        }
        set(newValue) {
            maxX = newValue.x
            maxY = newValue.y
            maxZ = newValue.z
            maxW = newValue.w
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case controlType
        case label
        case x
        case y
        case z
        case w
        case minX
        case maxX
        case minY
        case maxY
        case minZ
        case maxZ
        case minW
        case maxW
    }
    
    public init(_ label: String, _ value: simd_int4, _ min: simd_int4, _ max: simd_int4, _ controlType: ControlType = .unknown, _ action: ((simd_int4) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        self.z = value.z
        self.w = value.w
        
        self.minX = min.x
        self.maxX = max.x
        
        self.minY = min.y
        self.maxY = max.y
        
        self.minZ = min.z
        self.maxZ = max.z
        
        self.minW = min.w
        self.maxW = max.w
    }
    
    public init(_ label: String, _ value: simd_int4 = simd_make_int4(0), _ controlType: ControlType = .unknown, _ action: ((simd_int4) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = value.x
        self.y = value.y
        self.z = value.z
        self.w = value.w
        
        self.minX = 0
        self.maxX = 100
        
        self.minY = 0
        self.maxY = 100
        
        self.minZ = 0
        self.maxZ = 100
        
        self.minW = 0
        self.maxW = 100
    }
    
    public init(_ label: String, _ controlType: ControlType = .unknown, _ action: ((simd_int4) -> Void)? = nil) {
        self.label = label
        self.controlType = controlType
        
        self.x = 0
        self.y = 0
        self.z = 0
        self.w = 0
        
        self.minX = 0
        self.maxX = 100
        
        self.minY = 0
        self.maxY = 100
        
        self.minZ = 0
        self.maxZ = 100
        
        self.minW = 0
        self.maxW = 100
    }
    
    func setup() {
        observers.append(observe(\.x) { [unowned self] _, _ in
            for action in self.actions {
                action(self.value)
            }
        })
        observers.append(observe(\.y) { [unowned self] _, _ in
            for action in self.actions {
                action(self.value)
            }
        })
        observers.append(observe(\.z) { [unowned self] _, _ in
            for action in self.actions {
                action(self.value)
            }
        })
        observers.append(observe(\.w) { [unowned self] _, _ in
            for action in self.actions {
                action(self.value)
            }
        })
    }
    
    deinit {
        observers = []
        actions = []
    }
}
