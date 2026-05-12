//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  Transparent Background & Circular Icon UI
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. بەشی ئایکۆنی بازنەیی و سووڕانەوە بە دەوریدا
            ZStack {
                // تیشکی ڕەنگاوڕەنگی سووڕاوە (بە تەواوی بە دەوری ئایکۆنەکەدا)
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .cyan, .blue]),
                            center: .center
                        )
                    )
                    .frame(width: 72, height: 72) // ڕێک بە قەبارەی بازنەکە
                    .blur(radius: isAnimating ? 8 : 4)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isAnimating)
                
                // هێڵی بازنەیی پشتەوە (ڕەساسی کاڵ)
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 4)
                    .frame(width: 68, height: 68)
                
                // بازنەی پێشکەوتن (شین) کە بە دەوری لۆگۆکەدا پڕ دەبێتەوە
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.overallProgress))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 68, height: 68)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: viewModel.overallProgress)
                
                // 💡 ئایکۆنی ئەپەکە - ئێستا تەواو بازنەییە
                FRAppIconView(app: app)
                    .frame(width: 58, height: 58)
                    .clipShape(Circle()) // 💡 گۆڕدرا بۆ بازنە
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .scaleEffect(isAnimating ? 1.02 : 0.98)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            .padding(.top, 10)
            
            // 2. بەشی ناوی بەرنامە و کەپسولی زیرەک
            VStack(spacing: 12) {
                Text("AshteMobile")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // کەپسولی زیرەک
                HStack(spacing: 6) {
                    if viewModel.isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        
                        Text("Ready")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.6)
                            .frame(width: 15, height: 15)
                        
                        Text("\(Int(viewModel.overallProgress * 100))%")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.primary.opacity(0.06))
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 10)
        // 💡 تێبینی: هەموو باکگراوندە سپی و شووشەییەکانم لابرد بۆ ئەوەی تەواو شەفاف بێت
        .onAppear {
            isAnimating = true
        }
    }
}
