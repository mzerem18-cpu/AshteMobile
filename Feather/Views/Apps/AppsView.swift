import SwiftUI
import CoreData
import NimbleViews

struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    @State private var searchText = ""
    @State private var selectedFilter = 0
    
    // هێنانی یارییە مۆرکراوەکان بۆ نیشاندانی پەنجەرەی ئینستاڵ
    @FetchRequest(
        entity: Signed.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
        animation: .snappy
    ) private var signedApps: FetchedResults<Signed>
    
    @State private var showInstallSheet = false
    
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
                        VStack(spacing: 20, alignment: .leading) {
                            
                            // 💡 بەشی کاردە گەورەکان (Featured IPA)
                            if !viewModel.apps.isEmpty {
                                Text("FEATURED IPA")
                                    .font(.subheadline).fontWeight(.bold).foregroundColor(.gray)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(viewModel.apps.prefix(3)) { app in
                                            FeaturedAppCard(app: app)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // بەشی گەڕان
                            HStack {
                                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                                TextField("Search IPA Files...", text: $searchText)
                            }
                            .padding(12).background(Color.white).cornerRadius(12).padding(.horizontal)
                            
                            // بەشی فلتەر (ALL, APP, GAMES)
                            Picker("", selection: $selectedFilter) {
                                Text("ALL").tag(0)
                                Text("APP").tag(1)
                                Text("GAMES").tag(2)
                            }
                            .pickerStyle(SegmentedPickerStyle()).padding(.horizontal)
                            
                            // 💡 لیستی هەموو یارییەکان
                            Text("All IPA Files")
                                .font(.title2).fontWeight(.bold).padding(.horizontal)
                            
                            VStack(spacing: 15) {
                                ForEach(filteredApps) { app in
                                    AllAppRowView(app: app)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Apps")
            .onAppear { if viewModel.apps.isEmpty { viewModel.fetchApps() } }
            
            // 🚀 گوێگرتن بۆ هاتنی نامەی ئینستاڵ!
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AshteMobile.installApp"))) { _ in
                self.showInstallSheet = true
            }
            // پەنجەرەی ئینستاڵ هەر لەم پەڕەیەدا دەکرێتەوە
            .sheet(isPresented: $showInstallSheet) {
                if let app = signedApps.first {
                    InstallPreviewView(app: app, isSharing: false)
                        .presentationDetents([.height(200)])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
}

// MARK: - کاردی گەورە (وەک وێنەی Angry Birds)
struct FeaturedAppCard: View {
    let app: RemoteApp
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: app.safeBannerURL ?? app.safeIconURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: { Color.blue.opacity(0.2) }
                .frame(width: 300, height: 160).clipped()
                
                if app.status?.lowercased() == "new" {
                    Text("NEW")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.red).clipShape(Capsule()).padding(10)
                }
            }
            
            HStack(spacing: 12) {
                AsyncImage(url: app.safeIconURL) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: { Color.gray.opacity(0.2) }
                .frame(width: 55, height: 55)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 3)
                .offset(y: -20).padding(.bottom, -20) // ئەمە ئایکۆنەکە دەهێنێتە سەرەوە
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name).font(.system(size: 16, weight: .bold)).foregroundColor(.primary)
                    Text(app.category ?? "Games").font(.system(size: 13)).foregroundColor(.secondary)
                }
                Spacer()
                
                // دوگمە شازەکەی GET کە MB دەخوێنێتەوە
                AppDownloadButton(app: app)
            }
            .padding(12).background(Color.white)
        }
        .frame(width: 300).background(Color.white).cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - لیستی ئاسایی خوارەوە
struct AllAppRowView: View {
    let app: RemoteApp
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack(alignment: .topLeading) {
                AsyncImage(url: app.safeIconURL) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: { Color.gray.opacity(0.2) }
                .frame(width: 65, height: 65)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                if app.status?.lowercased() == "new" {
                    Text("NEW")
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Color.red).clipShape(Capsule()).offset(x: -5, y: -5)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.system(size: 16, weight: .bold)).foregroundColor(.primary)
                Text(app.category ?? "App").font(.system(size: 13)).foregroundColor(.secondary)
                Text("v\(app.version ?? "1.0") • \(app.size ?? "Unknown")").font(.system(size: 11)).foregroundColor(.gray)
            }
            Spacer()
            
            // دوگمە شازەکەی GET کە MB دەخوێنێتەوە
            AppDownloadButton(app: app)
        }
        .padding(12).background(Color.white).cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 🚀 دوگمەی GET کە دەبێتە بازنەی سووڕاوە و MB دەخوێنێتەوە!
struct AppDownloadButton: View {
    let app: RemoteApp
    @ObservedObject var downloadManager = DownloadManager.shared
    
    @State private var isDownloading = false
    @State private var isSigning = false
    @State private var progress: Double = 0
    @State private var mbString: String = ""
    
    let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
        animation: .snappy
    ) private var importedApps: FetchedResults<Imported>
    
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var certificates: FetchedResults<CertificatePair>

    var body: some View {
        Button(action: handleGet) {
            if isDownloading || isSigning {
                HStack(spacing: 6) {
                    ZStack {
                        Circle().stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: isSigning ? 1.0 : progress)
                            .stroke(isSigning ? Color.orange : Color.blue, lineWidth: 3)
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 18, height: 18)
                    
                    Text(isSigning ? "Signing" : mbString)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSigning ? .orange : .blue)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Color.blue.opacity(0.1)).clipShape(Capsule())
            } else {
                Text("GET")
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.blue)
                    .padding(.horizontal, 18).padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1)).clipShape(Capsule())
            }
        }
        .disabled(isDownloading || isSigning)
        .onReceive(timer) { _ in checkDownloadProgress() }
    }
    
    func handleGet() {
        guard let url = app.actualDownloadURL else { return }
        let id = "AshteMobileStore_\(app.id)"
        _ = downloadManager.startDownload(from: url, id: id)
        isDownloading = true
    }
    
    func checkDownloadProgress() {
        if let dl = downloadManager.manualDownloads.first(where: { $0.id.contains(app.id) }) {
            isDownloading = true
            let overall = dl.onlyArchiving ? dl.unpackageProgress : (0.3 * dl.unpackageProgress) + (0.7 * dl.progress)
            progress = overall
            
            if dl.totalBytes > 0 {
                let mb = Double(dl.bytesDownloaded) / 1048576.0
                mbString = String(format: "%.1f MB", mb)
            } else {
                mbString = "..."
            }
        } else if isDownloading {
            isDownloading = false
            startSigning()
        }
    }
    
    func startSigning() {
        isSigning = true
        let selectedIndex = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
        guard certificates.indices.contains(selectedIndex) else {
            isSigning = false; return
        }
        let cert = certificates[selectedIndex]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let latestApp = importedApps.first else {
                isSigning = false; return
            }
            
            FR.signPackageFile(latestApp, using: OptionsManager.shared.options, icon: nil, certificate: cert) { signError in
                DispatchQueue.main.async {
                    isSigning = false
                    if signError == nil {
                        // 🚀 ناردنی فەرمان بۆ هێنانە سەرەوەی پەنجەرەی ئینستاڵ
                        NotificationCenter.default.post(name: NSNotification.Name("AshteMobile.installApp"), object: nil)
                    }
                }
            }
        }
    }
}
