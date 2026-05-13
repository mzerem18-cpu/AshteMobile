import SwiftUI
import NimbleViews

struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    @State private var searchText = ""
    @State private var selectedFilter = 0
    
    var filteredApps: [RemoteApp] {
        var apps = viewModel.apps
        if selectedFilter == 1 { apps = apps.filter { $0.category?.lowercased() == "apps" } }
        else if selectedFilter == 2 { apps = apps.filter { $0.category?.lowercased() == "games" } }
        
        if !searchText.isEmpty { apps = apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        return apps
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                                TextField("Search IPA Files...", text: $searchText)
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            Picker("", selection: $selectedFilter) {
                                Text("ALL").tag(0)
                                Text("APP").tag(1)
                                Text("GAMES").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 15) {
                                Text("All IPA Files")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                ForEach(filteredApps) { app in
                                    NavigationLink(destination: AppDetailView(app: app)) {
                                        AppCardView(app: app)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Featured IPA")
            .onAppear { if viewModel.apps.isEmpty { viewModel.fetchApps() } }
        }
    }
}

// MARK: - دیزاینی کاردەکان
struct AppCardView: View {
    var app: RemoteApp
    @State private var isAdded = false
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: app.fullIconURL) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: { Color.gray.opacity(0.2) }
                .frame(width: 65, height: 65)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                if app.status?.lowercased() == "new" {
                    Text("NEW")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: -5, y: -5)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.system(size: 16, weight: .bold))
                Text(app.category ?? "App").font(.system(size: 13)).foregroundColor(.secondary)
                Text("\(app.version ?? "1.0") • \(app.size ?? "Unknown")").font(.system(size: 11)).foregroundColor(.gray)
            }
            Spacer()
            
            Button(action: {
                guard let url = app.actualDownloadURL else { return }
                let id = "AshteMobileStore_\(UUID().uuidString)"
                
                // 🔥 بەبێ ناساندنی پێشوەختە ڕاستەوخۆ بانگی دەکەین بۆ ئەوەی ئێرۆر نەدات
                _ = DownloadManager.shared.startDownload(from: url, id: id)
                
                withAnimation { isAdded = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { isAdded = false } }
            }) {
                Text(isAdded ? "ADDED" : "GET")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isAdded ? .gray : .blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(isAdded ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
            .disabled(isAdded)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - پەڕەی زانیارییەکانی یارییەکە
struct AppDetailView: View {
    var app: RemoteApp
    @State private var isAdded = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .bottom) {
                    if let bannerURL = app.fullBannerURL {
                        AsyncImage(url: bannerURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom)
                        }
                        .frame(height: 220).clipped()
                    } else {
                        LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom)
                            .frame(height: 220)
                    }
                    LinearGradient(gradient: Gradient(colors: [.clear, Color(UIColor.systemBackground)]), startPoint: .top, endPoint: .bottom).frame(height: 60)
                }
                
                HStack(alignment: .top, spacing: 16) {
                    AsyncImage(url: app.fullIconURL) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: { Color.gray.opacity(0.2) }
                    .frame(width: 90, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(app.name).font(.system(size: 24, weight: .bold))
                        Text(app.category ?? "Games").font(.system(size: 15)).foregroundColor(.secondary)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { _ in Image(systemName: "star.fill").foregroundColor(.orange).font(.system(size: 12)) }
                            Text("(4.9)").font(.system(size: 12)).foregroundColor(.gray)
                        }
                        
                        HStack {
                            Button(action: {
                                guard let url = app.actualDownloadURL else { return }
                                let id = "AshteMobileStore_\(UUID().uuidString)"
                                _ = DownloadManager.shared.startDownload(from: url, id: id)
                                
                                withAnimation { isAdded = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { isAdded = false } }
                            }) {
                                Text(isAdded ? "Added to Library" : "Get")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                    .background(isAdded ? Color.green : Color.blue)
                                    .clipShape(Capsule())
                            }
                            .disabled(isAdded)
                        }
                        .padding(.top, 4)
                    }
                    Spacer()
                }
                .padding(.horizontal).offset(y: -40).padding(.bottom, -40)
                
                HStack(spacing: 15) {
                    InfoPill(icon: "tag.fill", text: "V \(app.version ?? "1.0")")
                    InfoPill(icon: "internaldrive.fill", text: app.size ?? "Unknown")
                }
                .padding(.horizontal)
                Divider().padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Description").font(.title3).fontWeight(.bold)
                    if let hackList = app.hack, !hackList.isEmpty {
                        ForEach(hackList, id: \.self) { hackItem in
                            HStack(alignment: .top) {
                                Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                                Text(hackItem).font(.system(size: 15)).foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Text("No description.").foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                
                Divider().padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Information").font(.title3).fontWeight(.bold)
                    InfoRow(title: "Developer", value: "AshteMobile")
                    InfoRow(title: "Category", value: app.category ?? "Games")
                    InfoRow(title: "Minimum iOS", value: "13.0")
                }
                .padding(.horizontal).padding(.bottom, 40)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoPill: View {
    var icon: String; var text: String
    var body: some View {
        HStack { Image(systemName: icon).foregroundColor(.blue); Text(text).font(.system(size: 13, weight: .semibold)) }
        .frame(maxWidth: .infinity).padding(.vertical, 12).background(Color.blue.opacity(0.08)).cornerRadius(12)
    }
}

struct InfoRow: View {
    var title: String; var value: String
    var body: some View {
        HStack { Text(title).foregroundColor(.secondary); Spacer(); Text(value).fontWeight(.medium) }.font(.system(size: 15))
    }
}
