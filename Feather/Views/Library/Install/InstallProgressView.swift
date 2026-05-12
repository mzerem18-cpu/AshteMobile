//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  Dynamic Island Style - Minimalist & Modern UI
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        HStack(spacing: 15) {
            
            // 1. ئایکۆنی بەرنامە بە شێوەی بازنەیی لەگەڵ هێڵی پێشکەوتن
            ZStack {
                // هێڵی پشتەوە (تراک)
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 3)
                    .frame(width: 56, height: 56)
                
                // هێڵی پێشکەوتن (ڕەنگاوڕەنگ)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.overallProgress))
                    .stroke(
                        LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.overallProgress)
                
                // ئایکۆنی ئەپەکە
                FRAppIconView(app: app)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            }
            
            // 2. ناوی بەرنامە و دۆخی دابەزین
            VStack(alignment: .leading, spacing: 4) {
                Text("AshteMobile")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(viewModel.isCompleted ? "Ready to open" : "Installing...")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 3. باجی ڕێژەی سەدی (زۆر شاز و سەرنجڕاکێش)
            Text("\(Int(viewModel.overallProgress * 100))%")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Capsule())
                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(16)
        // باکگراوندی کەپسولی شووشەیی شاز
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        // هێڵێکی زۆر تەنکی درەوشاوە بە دەوری کەپسولەکەدا
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
}
