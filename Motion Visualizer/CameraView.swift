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
                Group {
                    if cameraManager.isDepthMapMode {
                        DepthMapView(arSession: cameraManager.arSession)
                    } else {
                        CameraPreview(arSession: cameraManager.arSession)
                    }
                }
                .ignoresSafeArea()
                
                VStack {
                    BlurredDistanceView(
                        distance: cameraManager.distanceInMeters,
                        confidenceLevel: cameraManager.confidenceLevel,
                        isLiDARAvailable: cameraManager.isLiDARAvailable,
                        isMetric: $cameraManager.isMetric
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
                
                VStack {
                    HStack {
                        Spacer()
                        VStack(spacing: 20) {
                            CameraModeToggleButton(isDepthMapMode: $cameraManager.isDepthMapMode)
                            UnitToggleButton(isMetric: $cameraManager.isMetric)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.trailing, 20)
            }
            .onAppear {
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

struct CameraModeToggleButton: View {
    @Binding var isDepthMapMode: Bool
    
    var body: some View {
        Button(action: {
            isDepthMapMode.toggle()
        }) {
            Image(systemName: "camera.filters")
                .foregroundColor(.white)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
}

struct UnitToggleButton: View {
    @Binding var isMetric: Bool
    
    var body: some View {
        Button(action: {
            isMetric.toggle()
        }) {
            Image(systemName: isMetric ? "ruler" : "ruler.fill")
                .foregroundColor(.white)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
    }
}

struct BlurredDistanceView: View {
    let distance: Float
    let confidenceLevel: ARConfidenceLevel
    let isLiDARAvailable: Bool
    @Binding var isMetric: Bool
    
    var body: some View {
        VStack {
            Text(formattedDistance)
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
    
    private var formattedDistance: String {
        if isMetric {
            return String(format: "Distance: %.2f m", distance)
        } else {
            let distanceInCm = distance * 100
            return String(format: "Distance: %.1f cm", distanceInCm)
        }
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
