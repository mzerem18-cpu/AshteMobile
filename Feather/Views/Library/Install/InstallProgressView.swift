//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  Ultra Premium & Minimalist Linear Progress UI by Gemini
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    @State private var _pulse = false
    
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        VStack(spacing: 28) {
            
            // 1. بەشی سەرەکی: کەپسولی زانیاری و بارێکی پێشکەوتنی درێژ
            VStack(spacing: 12) {
                
                // 💡 کەپسولی زانیاری سەرەکی نوێ
                HStack(spacing: 12) {
                    
                    // 💡 ئایقۆنی ئەپی بچووکراوە لەگەڵ سووڕانەوە بازنەیی دەوری
                    ZStack {
                        // تیشکی ڕەنگاوڕەنگی سووڕاوە دەوری
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(colors: [.cyan, .blue, .purple, .cyan]),
                                    center: .center
                                )
                            )
                            .frame(width: 46, height: 46)
                            .blur(radius: _pulse ? 8 : 4)
                            .scaleEffect(_pulse ? 1.05 : 0.95)
                            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: _pulse)
                        
                        FRAppIconView(app: app)
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .frame(width: 46, height: 46)
                    
                    // ناوی ئەپ و دۆخی داونلود
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AshteMobile")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // کەپسولی دۆخی داونلود
                        HStack(spacing: 6) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(0.6)
                                .frame(width: 15, height: 15)
                            
                            Text("Installing • \(Int(viewModel.overallProgress * 100))%")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                
                // 💡 بارێکی پێشکەوتنی درێژی هێڵی (Linear Progress Bar)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 5)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.cyan, .blue, .purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(viewModel.overallProgress) * CGFloat(230), height: 5)
                        .animation(.interactiveSpring(response: 0.6, dampingFraction: 0.8), value: viewModel.overallProgress)
                }
                .frame(width: 230)
                .padding(.horizontal, 20)
            }
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
        // چوارچێوەیەکی کاڵ
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.6), .clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .onAppear {
            _pulse = true
        }
    }
}
