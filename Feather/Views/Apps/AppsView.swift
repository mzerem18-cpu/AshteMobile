import SwiftUI
import CoreData
import Combine
import NimbleViews
import NimbleExtensions

struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    @State private var selectedApp: RemoteApp?
    
    // 💡 هێنانی یارییە مۆرکراوەکان بۆ ئەوەی ئینستاڵیان بکەین
    @FetchRequest(
        entity: Signed.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
        animation: .snappy
    ) private var signedApps: FetchedResults<Signed>
    
    @State private var showInstallSheet = false
    @State private var appToInstall: Signed?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading apps...")
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Text(error).padding()
                        Button("Try Again") { viewModel.fetchApps() }.buttonStyle(.bordered)
                    }
                } else {
                    List(viewModel.apps) { app in
                        AppRowView(app: app) {
                            self.selectedApp = app
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Apps")
            .onAppear {
                if viewModel.apps.isEmpty { viewModel.fetchApps() }
            }
            // پەردەی داونلۆد و مۆرکردن
            .sheet(item: $selectedApp) { app in
                AppInstallSheetView(app: app)
                    .presentationDetents([.height(290)])
            }
            // 🚀 ئەمە چارەسەرە گەورەکەیە! گوێ دەگرێت بۆ فەرمانی ئینستاڵ
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AshteMobile.installApp"))) { _ in
                if let latest = signedApps.first {
                    self.appToInstall = latest
                    self.showInstallSheet = true
                }
            }
            // 🚀 کردنەوەی پەنجەرەی ڕاستەقینەی ئینستاڵ
            .sheet(isPresented: $showInstallSheet) {
                if let app = appToInstall {
                    InstallPreviewView(app: app, isSharing: false)
                        .presentationDetents([.height(200)])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
}

struct AppRowView: View {
    var app: RemoteApp
    var onInstall: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: app.fullIconURL) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: { Color.gray.opacity(0.2) }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.system(size: 16, weight: .bold))
                Text(app.version ?? "Unknown")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            Button(action: onInstall) {
                Text("GET")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppInstallSheetView: View {
    var app: RemoteApp
    @Environment(\.dismiss) var dismiss // بۆ داخستنی پەردەکە پاش تەواوبوون
    
    @State private var progress: Double = 0.0
    @State private var isCompleted: Bool = false
    @State private var statusText: String = "Connecting..."
    @State private var stepText: String = "Preparing"
    @State private var isDownloading = false
    
    @ObservedObject var downloadManager = DownloadManager.shared
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
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                AsyncImage(url: app.fullIconURL) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: { Color.gray.opacity(0.3) }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusText)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    Text(app.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: isCompleted ? "checkmark.square.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 12))
                        Text(stepText)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(isCompleted ? .teal : .blue)
                    .padding(.top, 2)
                }
                Spacer()
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(progress))
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(26)
        .onAppear { startNativeDownload() }
        .onReceive(timer) { _ in checkDownloadProgress() }
    }
    
    func startNativeDownload() {
        guard let url = app.actualDownloadURL else {
            statusText = "Invalid URL"
            stepText = "Please check your site JSON"
            return
        }
        isDownloading = true
        let id = "AshteMobileStore_\(UUID().uuidString)"
        _ = downloadManager.startDownload(from: url, id: id)
    }
    
    func checkDownloadProgress() {
        if isCompleted || !isDownloading { return }
        
        if let dl = downloadManager.manualDownloads.first {
            statusText = "Downloading..."
            let overall = dl.onlyArchiving ? dl.unpackageProgress : (0.3 * dl.unpackageProgress) + (0.7 * dl.progress)
            self.progress = overall * 0.8 // تا ٨٠٪ دەڕوات
            
            if dl.totalBytes > 0 {
                let mbD = Double(dl.bytesDownloaded) / 1048576.0
                let mbT = Double(dl.totalBytes) / 1048576.0
                self.stepText = String(format: "%.1f MB / %.1f MB", mbD, mbT)
            }
        } else {
            // ئەگەر داونلۆدەکە دیارنەما واتە تەواو بووە
            if progress > 0.05 {
                isDownloading = false
                startSigning()
            }
        }
    }
    
    func startSigning() {
        self.statusText = "Signing App..."
        self.stepText = "Applying Certificate"
        withAnimation { self.progress = 0.9 } // دەبێتە ٩٠٪
        
        let selectedIndex = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
        guard certificates.indices.contains(selectedIndex) else {
            self.statusText = "Error"
            self.stepText = "No Certificate Selected"
            return
        }
        let cert = certificates[selectedIndex]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard let latestApp = importedApps.first else { return }
            
            FR.signPackageFile(
                latestApp,
                using: OptionsManager.shared.options,
                icon: nil,
                certificate: cert
            ) { signError in
                DispatchQueue.main.async {
                    if signError == nil {
                        withAnimation { self.progress = 1.0 }
                        self.isCompleted = true
                        self.statusText = "Ready to Install"
                        self.stepText = "Opening Install Prompt..."
                        
                        // 🚀 داخستنی ئەم پەردەیە و ناردنی فەرمانی ئینستاڵ
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            dismiss() // پەردەی داونلۆد دادەخات
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                NotificationCenter.default.post(name: NSNotification.Name("AshteMobile.installApp"), object: nil)
                            }
                        }
                    }
                }
            }
        }
    }
}
