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
        ZStack {
            CameraPreview(arSession: cameraManager.arSession)
                .ignoresSafeArea()
            
            VStack {
                BlurredDistanceView(distance: cameraManager.distanceInMeters)
                Spacer()
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
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
