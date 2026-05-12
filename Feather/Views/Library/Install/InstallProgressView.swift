//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  Transparent Native Sheet Integration
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            
            // 1. ئایکۆنی بەرنامە بە شێوەی بازنەیی لەگەڵ هێڵی پێشکەوتن
            ZStack {
                // هێڵی پشتەوە (تراک)
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                // هێڵی پێشکەوتن بە ڕەنگی شین
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.overallProgress))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.overallProgress)
                
                // ئایکۆنی ئەپەکە
                FRAppIconView(app: app)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            }
            
            // 2. ناوی بەرنامە و دۆخی دابەزین
            VStack(alignment: .leading, spacing: 4) {
                Text("AshteMobile")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(viewModel.isCompleted ? "Ready to open" : "Installing...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 3. باجی ڕێژەی سەدی (سادە و مۆدێرن)
            Text("\(Int(viewModel.overallProgress * 100))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(viewModel.isCompleted ? .white : .blue)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    viewModel.isCompleted ? Color.green : Color.blue.opacity(0.12)
                )
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        // 💡 تێبینی گرنگ: کەمێک بۆشاییم داوەتە خوارەوەی بۆ ئەوەی بەر وشەی Completed نەکەوێت
        .padding(.bottom, 30) 
        .padding(.top, 5)
        
        // 💡 هیچ Background و Shadow و Overlay لێرەدا نییە تا بە تەواوی شەفاف بێت!
    }
}
