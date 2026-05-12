//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  Safe Modern Design
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    @State private var _isPulsing = false
    
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            // بەشی ئایکۆن و بازنەی پێشکەوتن
            ZStack {
                // تیشکێکی شین لە پشت ئایکۆنەکە
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 90, height: 90)
                    .blur(radius: 15)
                
                // بازنەی خوارەوە (خۆڵەمێشی)
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 7)
                    .frame(width: 85, height: 85)
                
                // بازنەی پێشکەوتن (شین)
                Circle()
                    .trim(from: 0, to: viewModel.overallProgress)
                    .stroke(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .frame(width: 85, height: 85)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: viewModel.overallProgress)
                
                // ئایکۆنی بەرنامەکە
                FRAppIconView(app: app)
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .scaleEffect(_isPulsing ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: _isPulsing)
            }
            
            // نووسینی ڕێژەی سەدی
            VStack(spacing: 5) {
                Text("Installing...")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.blue)
            }
            
            // باری پێشکەوتنی ڕاست (Linear Bar)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 6)
                
                Capsule()
                    .fill(Color.blue)
                    .frame(width: 160 * viewModel.overallProgress, height: 6)
                    .animation(.spring(), value: viewModel.overallProgress)
            }
            .frame(width: 160)
        }
        .padding(30)
        .background(.ultraThinMaterial) // ستایلی شووشەیی
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
        .onAppear {
            _isPulsing = true
        }
    }
}
