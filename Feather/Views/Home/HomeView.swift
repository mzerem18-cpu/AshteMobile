//
//  HomeView.swift
//  AshteMobile
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

        if img.hasPrefix("http") {
            return URL(string: img)
        }

        return URL(string: "https://ashtemobile.site/\(img)")
    }

    var fullBannerURL: URL? {
        if let ban = banner {
            if ban.hasPrefix("http") {
                return URL(string: ban)
            }

            return URL(string: "https://ashtemobile.site/\(ban)")
        }

        return fullImageURL
    }
}

// MARK: - Home View

struct HomeView: View {

    @State private var apps: [HomeApp] = []
    @State private var currentBanner = 0

    let myCustomBanners = [
        "https://ashtemobile.site/img/t.png",
        "https://ashtemobile.site/img/i.png"
    ]

    let myCustomLinks = [
        "https://t.me/ashtemobile",
        "https://www.instagram.com/ashtemobile"
    ]

    let timer = Timer.publish(
        every: 4,
        on: .main,
        in: .common
    ).autoconnect()

    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(
            grouping: apps,
            by: { $0.category ?? "Apps" }
        )

        return dict.sorted { $0.key < $1.key }
    }

    var body: some View {

        ZStack {

            // MARK: Background

            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            NBNavigationView("Discover") {

                ScrollView(.vertical, showsIndicators: false) {

                    VStack(spacing: 35) {

                        // MARK: Banner

                        TabView(selection: $currentBanner) {

                            ForEach(0..<myCustomBanners.count, id: \.self) { index in

                                Button {

                                    if index < myCustomLinks.count,
                                       let url = URL(string: myCustomLinks[index]) {

                                        UIApplication.shared.open(url)
                                    }

                                } label: {

                                    AsyncImage(
                                        url: URL(string: myCustomBanners[index])
                                    ) { image in

                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)

                                    } placeholder: {

                                        RoundedRectangle(cornerRadius: 28)
                                            .fill(Color.white.opacity(0.08))
                                    }
                                }
                                .buttonStyle(.plain)
                                .tag(index)
                            }
                        }
                        .frame(
                            height: (UIScreen.main.bounds.width - 40) * 0.56
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 28,
                                style: .continuous
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(
                                    Color.white.opacity(0.12),
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: .black.opacity(0.15),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
                        .padding(.horizontal, 20)
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                        .onReceive(timer) { _ in

                            withAnimation(.easeInOut(duration: 0.5)) {

                                currentBanner =
                                (currentBanner + 1)
                                % myCustomBanners.count
                            }
                        }

                        // MARK: Categories

                        VStack(alignment: .leading, spacing: 35) {

                            ForEach(groupedApps, id: \.0) { category, categoryApps in

                                VStack(alignment: .leading, spacing: 18) {

                                    HStack {

                                        Text(category)
                                            .font(.largeTitle.bold())

                                        Spacer()

                                        Text("See All")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 20)

                                    ScrollView(
                                        .horizontal,
                                        showsIndicators: false
                                    ) {

                                        LazyHStack(spacing: 18) {

                                            ForEach(categoryApps) { app in

                                                Link(
                                                    destination: URL(
                                                        string: app.url
                                                    )!
                                                ) {

                                                    HomeAppCardView(app: app)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 10)
                                    }
                                }
                            }
                        }

                        // MARK: Footer

                        SocialMediaFooter()
                            .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .task {
            await loadApps()
        }
    }

    // MARK: Load Apps

    private func loadApps() async {

        guard let url = URL(
            string: "https://ashtemobile.site/ipaas.json"
        ) else {
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {

            let (data, _) = try await URLSession.shared.data(
                for: request
            )

            let decoded = try JSONDecoder().decode(
                [HomeApp].self,
                from: data
            )

            await MainActor.run {
                self.apps = decoded
            }

        } catch {

            print("Error loading apps: \(error)")
        }
    }
}

// MARK: - App Card

struct HomeAppCardView: View {

    let app: HomeApp

    var body: some View {

        VStack(spacing: 14) {

            AsyncImage(url: app.fullImageURL) { image in

                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)

            } placeholder: {

                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.08))
            }
            .frame(width: 84, height: 84)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: .black.opacity(0.12),
                radius: 12,
                x: 0,
                y: 6
            )

            VStack(spacing: 4) {

                Text(app.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(app.category ?? "App")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("OPEN")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(

                    LinearGradient(
                        colors: [
                            .blue,
                            .purple
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
        }
        .padding(16)
        .frame(width: 150, height: 215)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    Color.white.opacity(0.10),
                    lineWidth: 1
                )
        )
        .shadow(
            color: .black.opacity(0.12),
            radius: 16,
            x: 0,
            y: 10
        )
    }
}

// MARK: - Footer

struct SocialMediaFooter: View {

    var body: some View {

        VStack(spacing: 22) {

            Text("Connect With Us")
                .font(.title2.bold())

            HStack(spacing: 24) {

                SocialButton(
                    icon: "paperplane.fill",
                    color: .blue,
                    url: "https://t.me/ashtemobile"
                )

                SocialButton(
                    icon: "camera.fill",
                    color: .purple,
                    url: "https://instagram.com/ashtemobile"
                )

                SocialButton(
                    icon: "play.tv.fill",
                    color: .black,
                    url: "https://tiktok.com/@ashtemobile"
                )
            }
        }
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Social Button

struct SocialButton: View {

    let icon: String
    let color: Color
    let url: String

    var body: some View {

        Button {

            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }

        } label: {

            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(Circle())
                .shadow(
                    color: color.opacity(0.4),
                    radius: 10,
                    x: 0,
                    y: 5
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Animation

struct ScaleButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {

        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(
                .spring(
                    response: 0.3,
                    dampingFraction: 0.6
                ),
                value: configuration.isPressed
            )
    }
}
