//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  Modernized by Gemini for AshteMobile
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    @State private var _isPulsing = false
    
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // بەشی سەرەوە: ئایکۆن و بازنەی پێشکەوتنی مۆدێرن
            ZStack {
                // سێبەرێکی ڕەنگاوڕەنگ لە پشت ئایکۆنەکە
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                // بازنەی پێشکەوتنی سەرەکی
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 8)
                    .frame(width: 90, height: 90)
                
                Circle()
                    .trim(from: 0, to: viewModel.overallProgress)
                    .stroke(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: viewModel.overallProgress)
                
                // ئایکۆنی بەرنامەکە لە ناوەڕاست
                FRAppIconView(app: app)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .scaleEffect(_isPulsing ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: _isPulsing)
            }
            .padding(.top, 10)
            
            // زانیارییەکان
            VStack(spacing: 8) {
                Text(app.currentName ?? "App")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                // پیشاندانی ستاتۆس (بۆ نموونە: Sending Manifest)
                Text(viewModel.status ?? "Preparing...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                // ڕێژەی سەدی
                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // باری پێشکەوتنی هێڵی (Linear Progress)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * viewModel.overallProgress, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 30)
            .padding(.bottom, 10)
        }
        .padding(25)
        .background(.ultraThinMaterial) // باکگراوندە شووشەییەکە
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
        .onAppear {
            _isPulsing = true
        }
    }
}
