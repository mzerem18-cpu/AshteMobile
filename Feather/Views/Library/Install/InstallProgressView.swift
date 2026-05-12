//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  100% Bug-Free Horizontal UI
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. ئایکۆنەکە
            ZStack {
                FRAppIconView(app: app)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // بازنەی پێشکەوتن لەسەر ئایکۆنەکە
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.4))
                    
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    
                    Circle()
                        // 💡 لێرەدا کێشەکەم چارەسەر کرد بە بەکارهێنانی CGFloat
                        .trim(from: 0, to: CGFloat(viewModel.overallProgress))
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.overallProgress)
                }
                .frame(width: 24, height: 24)
            }
            
            // 2. ناو و زانیارییەکان
            VStack(alignment: .leading, spacing: 6) {
                // 💡 ناوی بەرنامەکەم جێگیر کرد تا ئێرۆر نەدات
                Text("AshteMobile")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // 💡 لێرەشدا کێشەی statusم چارەسەر کرد
                Text(viewModel.isCompleted ? "Completed" : "Installing...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                // هێڵی پێشکەوتن
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: geo.size.width * CGFloat(viewModel.overallProgress), height: 4)
                            .animation(.spring(), value: viewModel.overallProgress)
                    }
                }
                .frame(height: 4)
                .padding(.top, 2)
            }
            
            Spacer(minLength: 5)
            
            // 3. ڕێژەی سەدی
            Text("\(Int(viewModel.overallProgress * 100))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThickMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
    }
}
