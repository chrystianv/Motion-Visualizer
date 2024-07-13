//
//  CameraPreview.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/13/24.
//

import SwiftUI
import ARKit

struct CameraPreview: UIViewRepresentable {
    let arSession: ARSession
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.session = arSession
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

