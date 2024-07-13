//
//  CameraPreview.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/13/24.
//

import SwiftUI

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        cameraManager.preview?.frame = view.bounds
        cameraManager.preview?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(cameraManager.preview!)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}


