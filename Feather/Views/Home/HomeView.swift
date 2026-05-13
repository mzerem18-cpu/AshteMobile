//
//  HomeView.swift
//  AshteMobile
//
//  Modern Public UI Version
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

// MARK: - Model

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

    // MARK: Categories

    var groupedApps: [(String, [HomeApp])] {

        let dict = Dictionary(
            grouping: apps,
            by: { $0.category ?? "Apps" }
        )

        return dict.sorted { $0.key < $1.key }
    }

    // MARK: UI

    var body: some View {

        ZStack {

            // Background

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

                        // MARK: Banner Slider

                        TabView(selection: $currentBanner) {

                            ForEach(0..<myCustomBanners.count, id: \.self) { index in

                                Button {

                                    if let url = URL(string: myCustomLinks[index]) {
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
                                            .fill(Color.gray.opacity(0.2))
                                    }
                                }
                                .buttonStyle(.plain)
                                .tag(index)
                            }
                        }
                        .frame(height: 210)
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
                        .shadow(
                            color: .black.opacity(0.12),
                            radius: 10,
                            x: 0,
                            y: 6
                        )
                        .padding(.horizontal, 20)
                        .tabViewStyle(
                            PageTabViewStyle(indexDisplayMode: .automatic)
                        )
                        .onReceive(timer) { _ in

                            withAnimation {

                                currentBanner =
                                (currentBanner + 1)
                                % myCustomBanners.count
                            }
                        }

                        // MARK: Categories

                        VStack(alignment: .leading, spacing: 30) {

                            ForEach(groupedApps, id: \.0) { category, categoryApps in

                                VStack(alignment: .leading, spacing: 16) {

                                    HStack {

                                        Text(category)
                                            .font(.title.bold())

                                        Spacer()

                                        Text("See All")
                                            .foregroundColor(.blue)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 20)

                                    ScrollView(
                                        .horizontal,
                                        showsIndicators: false
                                    ) {

                                        LazyHStack(spacing: 18) {

                                            ForEach(categoryApps) { app in

                                                Button {

                                                    let generator =
                                                    UIImpactFeedbackGenerator(
                                                        style: .medium
                                                    )

                                                    generator.impactOccurred()

                                                    if let url = URL(
                                                        string: app.url
                                                    ) {

                                                        UIApplication.shared.open(url)
                                                    }

                                                } label: {

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

        VStack(spacing: 12) {

            // App Image

            AsyncImage(url: app.fullImageURL) { image in

                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)

            } placeholder: {

                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 80, height: 80)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
            )
            .shadow(
                color: .black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )

            // App Info

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

            // OPEN Button

            HStack(spacing: 5) {

                Image(systemName: "arrow.down.circle.fill")

                Text("OPEN")
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(

                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
        }
        .padding(15)
        .frame(width: 135, height: 200)
        .background(
            Color(.secondarySystemBackground)
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
                    Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Footer

struct SocialMediaFooter: View {

    var body: some View {

        VStack(spacing: 20) {

            Text("Connect With Us")
                .font(.title3.bold())

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
        .padding(.vertical, 25)
        .frame(maxWidth: .infinity)
        .background(
            Color(.secondarySystemBackground)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
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
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 55, height: 55)
                .background(color)
                .clipShape(Circle())
                .shadow(
                    color: color.opacity(0.3),
                    radius: 6,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Animation

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
