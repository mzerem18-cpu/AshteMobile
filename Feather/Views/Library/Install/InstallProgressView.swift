//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  Apple Native Minimalist Style
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            
            // 1. ئایکۆنی ئەپەکە - بە سادەیی و جوانی
            FRAppIconView(app: app)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // 2. زانیارییەکان و هێڵی پێشکەوتن
            VStack(alignment: .leading, spacing: 8) {
                
                // ناوی بەرنامە و ڕێژەی سەدی لە یەک هێڵدا
                HStack {
                    Text("AshteMobile")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                }
                
                // دۆخی دابەزین
                Text(viewModel.isCompleted ? "Ready to install" : "Sending Manifest...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                // 3. هێڵی پێشکەوتن (Progress Bar)ی زۆر خاوێن
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // باکگراوندی هێڵەکە
                        Capsule()
                            .fill(Color(UIColor.tertiarySystemFill))
                        
                        // هێڵی پڕبوونەوە بە ڕەنگی شین
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: geo.size.width * CGFloat(viewModel.overallProgress))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.overallProgress)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(20)
        // باکگراوندی کارتەکە کە لەگەڵ دۆخی تاريک و ڕووناکی مۆبایل دەگونجێت
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
}
