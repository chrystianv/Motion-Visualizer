//
//  CameraView.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/13/24.
//

import SwiftUI
import ARKit
import DGCharts

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isChartVisible = false
    @State private var isInfoPopupPresented = false

    
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
                   
                   VStack {
                       HStack {
                           Spacer()
                           VStack(spacing: 20) {
                               CameraModeToggleButton(isDepthMapMode: $cameraManager.isDepthMapMode)
                               UnitToggleButton(isMetric: $cameraManager.isMetric)
                               ChartToggleButton(isChartVisible: $isChartVisible)
                               InfoButton(isPresented: $isInfoPopupPresented)
                           }
                       }
                       Spacer()
                   }
                   .padding(.top, 60)
                   .padding(.trailing, 20)
                   
                   if isChartVisible {
                       VStack {
                           Spacer()
                           DistanceChartView(cameraManager: cameraManager)
                               .frame(height: geometry.size.height / 3)
                               .padding(.horizontal)
                               .background(.ultraThinMaterial)
                               .cornerRadius(10)
                               .padding(.bottom, 20)
                       }
                   }
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
                           .sheet(isPresented: $isInfoPopupPresented) {
                               InfoPopupView(isPresented: $isInfoPopupPresented)
                           }
                       }
                   }
               }


struct InfoButton: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        Button(action: {
            isPresented = true
        }) {
            Image(systemName: "info.circle")
                .foregroundColor(.white)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
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

struct ChartToggleButton: View {
    @Binding var isChartVisible: Bool
    
    var body: some View {
        Button(action: {
            isChartVisible.toggle()
        }) {
            Image(systemName: "chart.xyaxis.line")
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
