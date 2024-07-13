//
//  CameraView.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/13/24.
//

import SwiftUI
import Foundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            CameraPreview(cameraManager: cameraManager)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        // TODO: Implement LiDAR functionality
                        print("LiDAR button tapped")
                    }) {
                        Image(systemName: "lidar.sensor")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom)
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
