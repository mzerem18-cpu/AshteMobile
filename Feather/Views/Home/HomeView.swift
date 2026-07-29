//
//  HomeView.swift
//  AshteMobile
//
//  Created for AshteMobile
//  Modified to redirect downloads to external website
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
    
    let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            NBNavigationView("Discover") {
                ScrollView {
                    VStack(spacing: 35) {
                        
                        // 1. بەشی وێنە لاکێشەییەکان (Banners)
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
                                            Color(UIColor.secondarySystemBackground)
                                                .overlay(Image(systemName: "photo").foregroundColor(.gray.opacity(0.5)))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .tag(index)
                                }
                            }
                            .frame(height: (UIScreen.main.bounds.width - 40) * (1948.0 / 3464.0))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .padding(.horizontal, 20)
                            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .onReceive(timer) { _ in
                                guard !myCustomBanners.isEmpty else { return }
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentBanner = (currentBanner + 1) % myCustomBanners.count
                                }
                            }
                        }
                        
                        // 2. بەشی یاری و بەرنامەکان
                        VStack(alignment: .leading, spacing: 30) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(alignment: .lastTextBaseline) {
                                        Text(category)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("See All")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 16) {
                                            ForEach(categoryApps) { app in
                                                Button(action: {
                                                    openWebsite()
                                                }) {
                                                    HomeAppCardView(app: app)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 15)
                                        .padding(.top, 5)
                                    }
                                }
                            }
                        }
                        
                        // 3. بەشی سۆشیاڵ میدیاکان
                        SocialMediaFooter()
                            .padding(.top, 10)
                            .padding(.bottom, 40)
                    }
                    .padding(.top, 15)
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
    
    // 💡 فەنکشنی کردنەوەی وێبسایتەکە
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

// MARK: - App Card View
struct HomeAppCardView: View {
    let app: HomeApp
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(UIColor.secondarySystemBackground)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            
            VStack(spacing: 2) {
                Text(app.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(app.category ?? "App")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 5)
            
            // 💡 لێرەدا GETم گۆڕی بۆ OPEN
            Text("OPEN")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(Color.blue.opacity(0.12))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
        .padding(14)
        .frame(width: 135, height: 200)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Social Media Footer
struct SocialMediaFooter: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Connect With Us")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 24) {
                SocialButton(icon: "paperplane.fill", color: .blue, url: "https://t.me/ashtemobile")
                SocialButton(icon: "camera.fill", color: Color(UIColor.systemPurple), url: "https://www.instagram.com/ashtemobile")
                SocialButton(icon: "play.tv.fill", color: .primary, url: "https://www.tiktok.com/@ashtemobile")
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 20)
    }
}

struct SocialButton: View {
    let icon: String
    let color: Color
    let url: String
    
    var body: some View {
        Button(action: {
            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
