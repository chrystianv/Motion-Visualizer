//
//  CameraView.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/13/24.
//

import SwiftUI
import ARKit

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreview(arSession: cameraManager.arSession)
                    .ignoresSafeArea()
                
                VStack {
                    BlurredDistanceView(
                        distance: cameraManager.distanceInMeters,
                        confidenceLevel: cameraManager.confidenceLevel,
                        isLiDARAvailable: cameraManager.isLiDARAvailable
                    )
                    Spacer()
                }
                
                Image(systemName: "scope")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .position(cameraManager.targetPosition)
                
                Text("(\(Int(cameraManager.targetPosition.x)), \(Int(cameraManager.targetPosition.y)))")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .padding(5)
                    .position(x: cameraManager.targetPosition.x, y: cameraManager.targetPosition.y + 30)
            }
            .onAppear {
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                cameraManager.updateTargetPosition(center)
                cameraManager.startSession()
            }
            .onDisappear {
                cameraManager.stopSession()
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        cameraManager.updateTargetPosition(value.location)
                    }
            )
        }
    }
}

struct BlurredDistanceView: View {
    let distance: Float
    let confidenceLevel: ARConfidenceLevel
    let isLiDARAvailable: Bool
    
    var body: some View {
        VStack {
            Text(String(format: "Distance: %.2f m", distance))
                .foregroundColor(colorForConfidence(confidenceLevel))
            Text(isLiDARAvailable ? "LiDAR Enabled" : "Using Stereo Depth")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .padding(.top)
    }
    
    private func colorForConfidence(_ confidence: ARConfidenceLevel) -> Color {
        switch confidence {
        case .low:
            return .red
        case .medium:
            return .yellow
        case .high:
            return .white
        @unknown default:
            return .gray
        }
    }
}
