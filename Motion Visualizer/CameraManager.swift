//
//  CameraManager.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/13/24.
//

import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var preview: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func setupCamera() {
        session.beginConfiguration()
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get camera device")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            preview = AVCaptureVideoPreviewLayer(session: session)
            preview?.videoGravity = .resizeAspectFill
            
            session.commitConfiguration()
        } catch {
            print("Failed to setup camera: \(error.localizedDescription)")
        }
    }
    
    func startSession() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func stopSession() {
        session.stopRunning()
    }
}
