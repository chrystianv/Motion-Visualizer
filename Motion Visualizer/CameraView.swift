//
//  CameraView.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/13/24.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreview(arSession: cameraManager.arSession)
                    .ignoresSafeArea()
                
                VStack {
                    BlurredDistanceView(distance: cameraManager.distanceInMeters)
                    Spacer()
                }
                
                Image(systemName: "scope")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .position(cameraManager.targetPosition)
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
    
    var body: some View {
        Text(String(format: "Distance: %.2f m", distance))
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            .padding(.top)
    }
}
