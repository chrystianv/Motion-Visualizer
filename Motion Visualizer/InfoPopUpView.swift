//
//  InfoPopUpView.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/18/24.
//

import SwiftUI

struct InfoPopupView: View {
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Description")) {
                    Text("The motion visualizer measures the distance between the mobile device and the object that it visualizes within the target, with a range of approximately 20 to 500 cm. It displays position and velocity (change in position per unit time) of the mobile device along the axis from the object to the mobile device. The target object is located at the origin, and the direction from the target object to the mobile device is defined as a positive direction. The graphical mode displays position and velocity with respect to time. Position and velocity values in white, yellow, and red text correspond to high precision, medium precision, and low precision, respectively.")
                }

                Section(header: Text("Operating Principle")) {
                    Text("The motion visualizer depends on a specialized LiDAR (light detection and ranging) sensor, which includes both an array of invisible infrared light beams and an infrared light detector. Infrared light beams reflect off of objects in front of the camera. The infrared light detector is able to measure differences in time of arrival of each beam, producing a depth map of the environment in the field of view. A single point selected on the camera screen corresponds with a single distance measurement on the depth map.")
                }

                Section(header: Text("About Motion Visualizer")) {
                    Text("Motion Visualizer is developed with the support of the National Science Foundation award #2114586 in collaboration with the American Modeling Teachers Association, Arizona State University, Georgetown University, and the leadership and development team.")
                }

                Section(header: Text("Leadership Team")) {
                    Text("Colleen Megowan Romanowicz, PI")
                    Text("Mina Johnson-Glenberg, Co-PI")
                    Text("Chrystian Vieyra, Co-PI")
                    Text("Rebecca Vieyra, Co-PI")
                    Text("Daniel O'Brien, Co-PI")
                }

            }
            .navigationTitle("Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
