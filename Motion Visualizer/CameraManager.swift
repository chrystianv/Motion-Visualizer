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
    @Published var confidenceLevel: ARConfidenceLevel = .high
    @Published var isLiDARAvailable: Bool = false
    @Published var isMetric: Bool = true
    @Published var isDepthMapMode: Bool = false

    private var imageResolution: CGSize = .zero

    override init() {
        self.targetPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        super.init()
        self.isLiDARAvailable = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
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
              let depthMap = frame.sceneDepth?.depthMap,
              let confidenceMap = frame.sceneDepth?.confidenceMap else {
            return
        }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        if imageResolution == .zero {
            imageResolution = CGSize(width: width, height: height)
        }
        
        let x = Int(targetPosition.x * CGFloat(width) / UIScreen.main.bounds.width)
        let y = Int((1 - targetPosition.y / UIScreen.main.bounds.height) * CGFloat(height))
        
        guard x >= 0, x < width, y >= 0, y < height else {
            return
        }
        
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        CVPixelBufferLockBaseAddress(confidenceMap, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(depthMap, .readOnly)
            CVPixelBufferUnlockBaseAddress(confidenceMap, .readOnly)
        }
        
        guard let depthBaseAddress = CVPixelBufferGetBaseAddress(depthMap),
              let confidenceBaseAddress = CVPixelBufferGetBaseAddress(confidenceMap) else {
            return
        }
        
        let depthBytesPerRow = CVPixelBufferGetBytesPerRow(depthMap)
        let confidenceBytesPerRow = CVPixelBufferGetBytesPerRow(confidenceMap)
        
        let depthStartAddress = depthBaseAddress.advanced(by: y * depthBytesPerRow + x * MemoryLayout<Float32>.size)
        let confidenceStartAddress = confidenceBaseAddress.advanced(by: y * confidenceBytesPerRow + x * MemoryLayout<UInt8>.size)
        
        guard depthStartAddress >= depthBaseAddress,
              depthStartAddress < depthBaseAddress.advanced(by: height * depthBytesPerRow),
              confidenceStartAddress >= confidenceBaseAddress,
              confidenceStartAddress < confidenceBaseAddress.advanced(by: height * confidenceBytesPerRow) else {
            return
        }
        
        let distanceAtTarget = depthStartAddress.assumingMemoryBound(to: Float32.self).pointee
        let confidenceAtTarget = confidenceStartAddress.assumingMemoryBound(to: UInt8.self).pointee
        
        DispatchQueue.main.async {
            if distanceAtTarget.isFinite && distanceAtTarget > 0 {
                self.distanceInMeters = distanceAtTarget
                self.confidenceLevel = ARConfidenceLevel(rawValue: Int(confidenceAtTarget)) ?? .high
            }
        }
    }
    
    func updateTargetPosition(_ position: CGPoint) {
        targetPosition = position
        updateDistanceToTarget()
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        updateDistanceToTarget()
    }
}

