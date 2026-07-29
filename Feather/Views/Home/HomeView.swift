//
//  HomeView.swift
//  AshteMobile
//
//  Created for AshteMobile
//  Modernized & Professional UI Redesign
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

// MARK: - Models
struct HomeApp: Codable, Identifiable {
    var id: String { url }
    let name: String
    let version: String?
    let category: String?
    let image: String?
    let size: String?
    let developer: String?
    let bundle: String?
    let url: String
    let status: String?
    let banner: String?
    let hack: [String]?

    var fullImageURL: URL? {
        guard let img = image else { return nil }
        if img.hasPrefix("http") { return URL(string: img) }
        return URL(string: "https://ashtemobile.site/\(img)")
    }
    
    var fullBannerURL: URL? {
        if let ban = banner {
            if ban.hasPrefix("http") { return URL(string: ban) }
            return URL(string: "https://ashtemobile.site/\(ban)")
        }
        return fullImageURL
    }
}

// MARK: - Main Home View
struct HomeView: View {
    @State private var apps: [HomeApp] = []
    
    // --- بەشی وێنە لاکێشەییەکان ---
    @State private var currentBanner = 0
    let myCustomBanners = [
        "https://ashtemobile.site/img/t.png",
        "https://ashtemobile.site/img/i.png"
    ]
    
    let myCustomLinks = [
        "https://t.me/ashtemobile",
        "https://www.instagram.com/ashtemobile"
    ]
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // باکگراوندێکی مۆدێرن و نەرم
            LinearGradient(
                gradient: Gradient(colors: [Color(UIColor.systemBackground), Color(UIColor.secondarySystemBackground)]),
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
            NBNavigationView("Discover") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 35) {
                        
                        // 1. بەشی وێنە لاکێشەییەکان (Banners) بە ستایلی نوێ
                        if !myCustomBanners.isEmpty {
                            TabView(selection: $currentBanner) {
                                ForEach(0..<myCustomBanners.count, id: \.self) { index in
                                    Button(action: {
                                        if index < myCustomLinks.count, let url = URL(string: myCustomLinks[index]) {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        AsyncImage(url: URL(string: myCustomBanners[index])) { image in
                                            image.resizable()
                                                 .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            ZStack {
                                                Color(UIColor.secondarySystemBackground)
                                                ProgressView()
                                            }
                                        }
                                    }
                                    .buttonStyle(ModernScaleButtonStyle())
                                    .tag(index)
                                }
                            }
                            .frame(height: (UIScreen.main.bounds.width - 40) * (1800.0 / 3464.0))
                            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                            .padding(.horizontal, 20)
                            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .onReceive(timer) { _ in
                                guard !myCustomBanners.isEmpty else { return }
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    currentBanner = (currentBanner + 1) % myCustomBanners.count
                                }
                            }
                        }
                        
                        // 2. بەشی یاری و بەرنامەکان بە دیزاینی App Store
                        VStack(alignment: .leading, spacing: 32) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 18) {
                                    
                                    // هێدەری بەشەکان
                                    HStack(alignment: .center) {
                                        Text(category)
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Button(action: {
                                            // بۆ داهاتوو: کردنەوەی لیستی هەموو بەرنامەکانی ئەم بەشە
                                        }) {
                                            HStack(spacing: 4) {
                                                Text("See All")
                                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .bold))
                                            }
                                            .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // لیستی بەرنامەکان
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 20) {
                                            ForEach(categoryApps) { app in
                                                Button(action: {
                                                    openWebsite()
                                                }) {
                                                    HomeAppCardView(app: app)
                                                }
                                                .buttonStyle(ModernScaleButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                    }
                                }
                            }
                        }
                        
                        // 3. بەشی سۆشیاڵ میدیاکان بە ئیفێکتی شوشەیی (Glassmorphism)
                        SocialMediaFooter()
                            .padding(.top, 15)
                            .padding(.bottom, 50)
                    }
                    .padding(.top, 20)
                }
                .refreshable {
                    await loadApps()
                }
            }
            .onAppear {
                Task { await loadApps() }
            }
        }
    }
    
    // فەنکشنی کردنەوەی وێبسایتەکە
    private func openWebsite() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if let url = URL(string: "https://ashtemobile.site") {
            UIApplication.shared.open(url)
        }
    }
    
    // هێنانی داتا
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.site/ipaas.json") else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            DispatchQueue.main.async {
                self.apps = decoded
            }
        } catch {
            print("Error loading apps: \(error)")
        }
    }
}

// MARK: - App Card View (Modern UI)
struct HomeAppCardView: View {
    let app: HomeApp
    
    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            
            // ئایکۆنی بەرنامە بە سێبەری پرۆفیشناڵ
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable()
                     .aspectRatio(contentMode: .fill)
            } placeholder: {
                ZStack {
                    Color.gray.opacity(0.1)
                    Image(systemName: "app.dashed")
                        .foregroundColor(.gray)
                        .font(.system(size: 30))
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
            
            // ناوی بەرنامە و جۆرەکەی
            VStack(spacing: 4) {
                Text(app.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(app.category ?? "App")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
            
            // دوگمەی داگرتن بە ستایلی مۆدێرن و ڕەنگی تێکەڵاو
            Text("OPEN")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(Capsule())
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .padding(16)
        .frame(width: 145, height: 215)
        // ئیفێکتی شوشەیی بۆ باکگراوندی کاردەکە
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Social Media Footer (Glassmorphism)
struct SocialMediaFooter: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Connect With Us")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 28) {
                SocialModernButton(icon: "paperplane.fill", colors: [Color.cyan, Color.blue], url: "https://t.me/ashtemobile")
                SocialModernButton(icon: "camera.fill", colors: [Color.purple, Color.orange], url: "https://www.instagram.com/ashtemobile")
                SocialModernButton(icon: "play.tv.fill", colors: [Color.black, Color.gray], url: "https://www.tiktok.com/@ashtemobile")
            }
        }
        .padding(.vertical, 30)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial) // ئیفێکتی شوشەیی
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Modern Social Button
struct SocialModernButton: View {
    let icon: String
    let colors: [Color]
    let url: String
    
    var body: some View {
        Button(action: {
            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 55, height: 55)
                .background(
                    LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .clipShape(Circle())
                .shadow(color: colors.first!.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ModernScaleButtonStyle())
    }
}

// MARK: - Custom Button Style for smooth animations
struct ModernScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
