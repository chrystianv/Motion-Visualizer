//
//  CameraManager.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/13/24.
//
import SwiftUI
import ARKit

class CameraManager: NSObject, ObservableObject, ARSessionDelegate {
    @Published var arSession = ARSession()
    @Published var distanceInMeters: Float = 0.0
    @Published var targetPosition: CGPoint
    
    private var imageResolution: CGSize = .zero
    
    override init() {
        self.targetPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
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
    
    func updateDistanceToTarget() {
        guard let frame = arSession.currentFrame,
              let depthMap = frame.sceneDepth?.depthMap else {
            print("No depth map available")
            return
        }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        // Update image resolution if needed
        if imageResolution == .zero {
            imageResolution = CGSize(width: width, height: height)
            print("Updated image resolution: \(imageResolution)")
        }
        
        // Convert target position to depth map coordinates
        // Note the change in y-coordinate calculation
        let x = Int(targetPosition.x * CGFloat(width) / UIScreen.main.bounds.width)
        let y = Int((1 - targetPosition.y / UIScreen.main.bounds.height) * CGFloat(height))
        
        // Ensure the coordinates are within the bounds of the depth map
        guard x >= 0, x < width, y >= 0, y < height else {
            print("Target position out of bounds: (\(x), \(y)), Depth map size: (\(width), \(height))")
            return
        }
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else {
            print("Unable to get base address of depth map")
            return
        }
        
        let bytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        let startAddress = baseAddress.advanced(by: y * bytesPerRow + x * MemoryLayout<Float32>.size)
        
        // Ensure we're not accessing memory outside the buffer
        guard startAddress >= baseAddress,
              startAddress < baseAddress.advanced(by: height * bytesPerRow) else {
            print("Calculated address is out of bounds")
            return
        }
        
        let distanceAtTarget = startAddress.assumingMemoryBound(to: Float32.self).pointee
        
        DispatchQueue.main.async {
            self.distanceInMeters = distanceAtTarget
        }
    }
    
    func updateTargetPosition(_ position: CGPoint) {
        targetPosition = position
        print("Target position updated: \(position)")
        updateDistanceToTarget()
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        updateDistanceToTarget()
    }
}
