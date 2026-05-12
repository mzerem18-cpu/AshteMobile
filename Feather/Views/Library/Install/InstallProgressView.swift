//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  Ultra Premium & Safe UI
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    @State private var _pulse = false
    
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            
            // 1. بەشی ئایکۆن و بازنەی پێشکەوتن
            ZStack {
                // باکگراوندی درەوشاوە لە پشت ئایکۆنەکە (Glow)
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                    .scaleEffect(_pulse ? 1.1 : 0.9)
                
                // هێڵی بازنەیی پشتەوە (تراکی سادە)
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 5)
                    .frame(width: 86, height: 86)
                
                // هێڵی پێشکەوتن بە ڕەنگی تێکەڵاوی مۆدێرن (Angular Gradient)
                Circle()
                    .trim(from: 0, to: viewModel.overallProgress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.cyan, .blue, .purple, .cyan]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 86, height: 86)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.overallProgress)
                
                // ئایکۆنی بەرنامەکە بە سێبەرێکی نەرمەوە
                FRAppIconView(app: app)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 10)
            
            // 2. بەشی دەق و کەپسولی زانیارییەکان
            VStack(spacing: 12) {
                // 💡 لێرەدا کێشەکەم چارەسەر کرد: ناوی بەرنامەکەم کرد بە جێگیر بۆ ئەوەی ئێرۆر نەدات
                Text("AshteMobile")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // کەپسولی نیشاندانی دۆخی دابەزین
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(0.7)
                        .frame(width: 15, height: 15)
                    
                    Text("Installing • \(Int(viewModel.overallProgress * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.06))
                .clipShape(Capsule())
            }
            .padding(.bottom, 10)
        }
        .padding(30)
        .frame(minWidth: 260)
        // باکگراوندی شووشەیی (Ultra Thin Material)
        .background(
            ZStack {
                Color(UIColor.systemBackground).opacity(0.6)
                Rectangle().fill(.ultraThinMaterial)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 25, x: 0, y: 12)
        // چوارچێوەیەکی زۆر کاڵ
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                _pulse = true
            }
        }
    }
}
