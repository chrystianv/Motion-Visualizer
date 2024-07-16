//
//  DepthMapView.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/16/24.
//

import SwiftUI
import ARKit
import MetalKit

struct DepthMapView: UIViewRepresentable {
    var arSession: ARSession
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        return mtkView
    }

    
    func updateUIView(_ uiView: MTKView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        var parent: DepthMapView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState?
        var depthTexture: MTLTexture?
        
        init(_ parent: DepthMapView) {
            self.parent = parent
            super.init()
            
            guard let device = MTLCreateSystemDefaultDevice() else {
                fatalError("Failed to create MTLDevice")
            }
            self.metalDevice = device
            
            guard let queue = metalDevice.makeCommandQueue() else {
                fatalError("Failed to create command queue")
            }
            self.metalCommandQueue = queue
            
            setupPipelineState()
        }
        
        func setupPipelineState() {
            guard let library = metalDevice.makeDefaultLibrary() else {
                print("Failed to create default library")
                return
            }
            
            guard let vertexFunction = library.makeFunction(name: "vertexShader") else {
                print("Failed to create vertex shader function")
                return
            }
            
            guard let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
                print("Failed to create fragment shader function")
                return
            }
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float  // Add this line
            
            do {
                pipelineState = try metalDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
                print("Successfully created pipeline state")
            } catch {
                print("Failed to create pipeline state: \(error)")
            }
        }
        
        
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            guard let currentFrame = parent.arSession.currentFrame,
                  let depthMap = currentFrame.sceneDepth?.depthMap,
                  let drawable = view.currentDrawable,
                  let commandBuffer = metalCommandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let pipelineState = self.pipelineState else {
                print("Error: Unable to get required resources for rendering")
                return
            }
            
            updateDepthTexture(depthMap: depthMap)
            
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
                  let depthTexture = self.depthTexture else {
                print("Error: Unable to create render encoder or depth texture")
                return
            }
            
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setFragmentTexture(depthTexture, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
        
        
        func updateDepthTexture(depthMap: CVPixelBuffer) {
            let width = CVPixelBufferGetWidth(depthMap)
            let height = CVPixelBufferGetHeight(depthMap)
            
            if depthTexture == nil || depthTexture?.width != width || depthTexture?.height != height {
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .r32Float, width: width, height: height, mipmapped: false)
                textureDescriptor.usage = [.shaderRead, .shaderWrite]
                depthTexture = metalDevice.makeTexture(descriptor: textureDescriptor)
            }
            
            guard let depthTexture = depthTexture else {
                print("Failed to create depth texture")
                return
            }
            
            CVPixelBufferLockBaseAddress(depthMap, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
            
            guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
                print("Error: Unable to get base address of depth map")
                return
            }
            
            let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
            
            let region = MTLRegionMake2D(0, 0, width, height)
            depthTexture.replace(region: region, mipmapLevel: 0, withBytes: baseAddress, bytesPerRow: bytesPerRow)
        }
    }

        
     
}
