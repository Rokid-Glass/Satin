//
//  Renderer+Background.swift
//  SatinSceneKitAR-iOS
//
//  Created by Reza Ali on 6/24/21.
//  Copyright © 2021 Hi-Rez. All rights reserved.
//

#if os(iOS)
import ARKit
import Satin

extension SatinSceneKitARRenderer {
    func setupBackgroundTextureCache() {
        // Create captured image texture cache
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        capturedImageTextureCache = textureCache
    }

    func updateBackground() {
        guard let frame = session.currentFrame else { return }
        updateBackgroundTextures(frame)

        if _updateBackgroundGeometry {
            updateBackgroundGeometry(frame)
            _updateBackgroundGeometry = false
        }
    }

    func updateBackgroundGeometry(_ frame: ARFrame) {
        guard let orientation = getOrientation() else { return }

        // Update the texture coordinates of our image plane to aspect fill the viewport
        let displayToCameraTransform = frame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()

        let geo = QuadGeometry()
        for (index, vertex) in geo.vertexData.enumerated() {
            let uv = vertex.uv
            let textureCoord = CGPoint(x: CGFloat(uv.x), y: CGFloat(uv.y))
            let transformedCoord = textureCoord.applying(displayToCameraTransform)
            geo.vertexData[index].uv = simd_make_float2(Float(transformedCoord.x), Float(transformedCoord.y))
        }

        backgroundMesh.geometry = geo
    }

    func updateBackgroundTextures(_ frame: ARFrame) {
        // Create two textures (Y and CbCr) from the provided frame's captured image
        let pixelBuffer = frame.capturedImage

        if CVPixelBufferGetPlaneCount(pixelBuffer) < 2 {
            return
        }

        capturedImageTextureY = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0)
        capturedImageTextureCbCr = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1)
    }

    func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)

        var texture: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, capturedImageTextureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)

        if status != kCVReturnSuccess {
            texture = nil
        }

        return texture
    }
}
#endif
