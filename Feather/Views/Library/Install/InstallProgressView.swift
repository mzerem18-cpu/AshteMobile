//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  VisionOS Inspired - Ultra Modern UI
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    // بۆ جووڵە و ئەنیمەیشنەکان
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 22) {
            
            // 1. بەشی ئایکۆن لەگەڵ باکگراوندە سووڕاوە خەیاڵییەکە
            ZStack {
                // تیشکی ڕەنگاوڕەنگی سووڕاوە (ئەنیمەیشنی مۆدێرن)
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .cyan, .blue]),
                            center: .center
                        )
                    )
                    .frame(width: 88, height: 88)
                    .blur(radius: isAnimating ? 12 : 6)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: isAnimating)
                
                // هێڵی بازنەیی پشتەوە
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 5)
                    .frame(width: 78, height: 78)
                
                // بازنەی پێشکەوتنی ڕاستەقینە (سپی)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.overallProgress))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 78, height: 78)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: viewModel.overallProgress)
                
                // ئایکۆنی ئەپەکە کە کەمێک هەناسە دەدات (گەورە و بچووک دەبێتەوە)
                FRAppIconView(app: app)
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                    .scaleEffect(isAnimating ? 1.02 : 0.98)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            .padding(.top, 5)
            
            // 2. بەشی ناوی بەرنامە و کەپسولی زیرەک
            VStack(spacing: 12) {
                Text("AshteMobile")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // کەپسولی زیرەک (دەگۆڕێت بەپێی دۆخی دابەزینەکە)
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
        .padding(.vertical, 30)
        .padding(.horizontal, 40)
        .frame(minWidth: 230)
        // دیزاینی شووشەیی زۆر شاز
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 15)
        // چوارچێوەیەکی تەنکی درەوشاوە
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.5), .clear, .white.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .onAppear {
            isAnimating = true // دەستپێکردنی جووڵەکان
        }
    }
}
