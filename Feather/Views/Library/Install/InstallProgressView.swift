//
//  InstallProgressView.swift
//  AshteMobile
//
//  Created by samara on 23.04.2025.
//  Ksign-Inspired UI (With Expanded Sheet Frame)
//

import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
    var app: AppInfoPresentable
    @ObservedObject var viewModel: InstallerStatusViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. بەشی سەرەوە: ئایکۆن و زانیارییەکان
            HStack(spacing: 16) {
                // ئایکۆنی ئەپەکە لەگەڵ ئیفێکتی تاریکبوون
                ZStack(alignment: .trailing) {
                    FRAppIconView(app: app)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    if !viewModel.isCompleted {
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 70 * (1.0 - CGFloat(viewModel.overallProgress)))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .animation(.spring(), value: viewModel.overallProgress)
                    }
                }
                
                // ناو و دۆخی بەرنامەکە
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.isCompleted ? "Install Complete" : "Preparing Install")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("AshteMobile")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isCompleted ? "checkmark.square.fill" : "paperplane.fill")
                            .font(.system(size: 12))
                        
                        Text(viewModel.isCompleted ? "Completed" : "Sending Manifest")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(viewModel.isCompleted ? .teal : .orange)
                    .padding(.top, 2)
                }
                
                Spacer()
            }
            
            // 2. هێڵی پێشکەوتن (دەدرەوشێتەوە)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: viewModel.isCompleted ? [.blue, .cyan] : [.orange, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(viewModel.overallProgress))
                        .shadow(color: viewModel.isCompleted ? Color.cyan.opacity(0.4) : Color.purple.opacity(0.4), radius: 6, x: 0, y: 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.overallProgress)
                }
            }
            .frame(height: 8)
            
            // 3. بەشی ڕێژەی سەدی
            HStack {
                Text("\(Int(viewModel.overallProgress * 100))%")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(viewModel.isCompleted ? .teal : .orange)
                
                Spacer()
                
                Text(viewModel.isCompleted ? "Ready to open" : "Keep AshteMobile open")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            // 4. دوگمەی "Open App" کە تەنها کاتێک تەواو بوو دەردەکەوێت
            if viewModel.isCompleted {
                Button(action: {
                    // لێرەدا دەتوانیت ئەکشنێک دابنێیت بۆ کردنەوەی ئەپەکە یان داخستنی پەردەکە
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "app.badge.checkmark")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Open App")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .teal], 
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.teal.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 10)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        // 💡 تێبینی گرنگ: ئەم دێڕە وا دەکات پەردەکە بە زۆر خۆی گەورە بکات بۆ ئەوەی دیزاینەکە جێی ببێتەوە
        .frame(minHeight: viewModel.isCompleted ? 280 : 220, alignment: .top)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.isCompleted)
    }
}
