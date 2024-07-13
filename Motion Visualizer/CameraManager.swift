//
//  CameraManager.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/13/24.
//

import SwiftUI
import ARKit

class CameraManager: NSObject, ObservableObject, ARSessionDelegate{
    @Published var session = AVCaptureSession()
    @Published var preview: AVCaptureVideoPreviewLayer?
    @Published var distanceInMeters: Float = 0.0
    @Published var arSession = ARSession()

    override init() {
        super.init()
        setupARSession()
    }
    
    func setupARSession() {
        arSession.delegate = self
    }


    func startSession() {
         let configuration = ARWorldTrackingConfiguration()
         configuration.frameSemantics = .sceneDepth
         arSession.run(configuration)
     }

      
    func stopSession() {
        arSession.pause()
    }
      
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        updateDistanceToCenter()
    }
    
    func updateDistanceToCenter() {
        guard let frame = arSession.currentFrame,
              let depthMap = frame.sceneDepth?.depthMap else {
            return
        }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        let centerX = width / 2
        let centerY = height / 2
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        if let baseAddress = CVPixelBufferGetBaseAddress(depthMap) {
            let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
            let startAddress = baseAddress.advanced(by: centerY * bytesPerRow + centerX * MemoryLayout<Float32>.size)
            let distanceAtCenter = startAddress.assumingMemoryBound(to: Float32.self).pointee
            
            DispatchQueue.main.async {
                self.distanceInMeters = distanceAtCenter
            }
        }
    }

    func setupCamera() {
        session.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get camera device")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            preview = AVCaptureVideoPreviewLayer(session: session)
            preview?.videoGravity = .resizeAspectFill
            
            session.commitConfiguration()
        } catch {
            print("Failed to setup camera: \(error.localizedDescription)")
        }
    }
    
     
    
}
