//
//  DistanceChartView.swift
//  Motion Visualizer
//
//  Created by Chrystian Vieyra on 7/17/24.
//

import SwiftUI
import DGCharts

struct DistanceChartView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    func makeUIView(context: Context) -> LineChartView {
        let chartView = LineChartView()
        chartView.rightAxis.enabled = false
        chartView.leftAxis.labelTextColor = .white
        chartView.xAxis.labelTextColor = .white
        chartView.legend.enabled = false
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = true
        
        return chartView
    }
    
    func updateUIView(_ uiView: LineChartView, context: Context) {
        let dataSet = LineChartDataSet(entries: cameraManager.distanceEntries, label: "Distance")
        dataSet.colors = [.white]
        dataSet.drawCirclesEnabled = false
        dataSet.mode = .cubicBezier
        dataSet.lineWidth = 2
        dataSet.drawValuesEnabled = false
        
        let data = LineChartData(dataSet: dataSet)
        uiView.data = data
        
        uiView.notifyDataSetChanged()
    }
}
