import SwiftUI
import CoreData
import Combine

struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    @State private var selectedApp: RemoteApp?
    
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
                            // کاتێک کلیک لە GET دەکرێت، پەردە شازەکە دەکاتەوە
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
            // پەردەی داونلۆد و ئینستاڵکردنەکە
            .sheet(item: $selectedApp) { app in
                AppInstallSheetView(app: app)
                    .presentationDetents([.height(290)])
            }
        }
    }
}

// دیزاینی بەرنامەکان (تەنها دوگمەی GETی تێدایە)
struct AppRowView: View {
    var app: RemoteApp
    var onInstall: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: app.fullIconURL) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
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

// 🔥 پەردە ڕاستەقینەکە کە داونلۆد و Sign و Install دەکات
struct AppInstallSheetView: View {
    var app: RemoteApp
    
    @State private var progress: Double = 0.0
    @State private var isCompleted: Bool = false
    @State private var statusText: String = "Connecting..."
    @State private var stepText: String = "Preparing"
    @State private var hasStartedDownload = false
    
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
                ZStack(alignment: .trailing) {
                    AsyncImage(url: app.fullIconURL) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isCompleted ? "Install Complete" : statusText)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(app.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: isCompleted ? "checkmark.square.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 12))
                        Text(isCompleted ? "Completed" : stepText)
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
                        .fill(LinearGradient(colors: isCompleted ? [.blue, .cyan] : [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(progress))
                        .shadow(color: isCompleted ? Color.cyan.opacity(0.4) : Color.blue.opacity(0.4), radius: 6, x: 0, y: 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(isCompleted ? .teal : .blue)
                Spacer()
                Text(isCompleted ? "Ready to open" : "Keep AshteMobile open")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(26)
        .onAppear {
            startNativeDownload()
        }
        .onReceive(timer) { _ in
            checkDownloadProgress()
        }
    }
    
    // فەنکشنی کردنەوەی کۆدی Base64 بۆ لینکی ڕاستەقینە بێ دەستکاریکردنی مۆدێل
    func getRealURL(from urlString: String) -> URL? {
        if let data = Data(base64Encoded: urlString),
           let decoded = String(data: data, encoding: .utf8),
           let url = URL(string: decoded) {
            return url
        }
        return URL(string: urlString)
    }
    
    func startNativeDownload() {
        guard let url = getRealURL(from: app.downloadURL) else {
            statusText = "Invalid URL"
            stepText = "Error"
            return
        }
        let id = "AshteMobileStore_\(UUID().uuidString)"
        _ = downloadManager.startDownload(from: url, id: id)
    }
    
    func checkDownloadProgress() {
        if isCompleted { return }
        
        // سەیر دەکات بزانێت داونلۆد لەناو مەنەجەرەکەدا ماوە یان نا
        if let dl = downloadManager.manualDownloads.first {
            hasStartedDownload = true
            statusText = "Downloading..."
            
            let overall = dl.onlyArchiving ? dl.unpackageProgress : (0.3 * dl.unpackageProgress) + (0.7 * dl.progress)
            self.progress = overall * 0.8 // داونلۆد ٨٠٪ی هێڵەکە دەگرێت
            
            if dl.totalBytes > 0 {
                let mbDownloaded = Double(dl.bytesDownloaded) / 1048576.0
                let mbTotal = Double(dl.totalBytes) / 1048576.0
                self.stepText = String(format: "%.1f MB / %.1f MB", mbDownloaded, mbTotal)
            } else {
                self.stepText = "Fetching files..."
            }
        } else if hasStartedDownload {
            // ئەگەر داونلۆد دیار نەما و پێشتر دەستی پێکردبوو، واتە تەواو بووە!
            hasStartedDownload = false
            startSigning()
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
        
        // چاوەڕێ دەکەین یەک چرکە تا فایلەکە دەچێتە ناو داتابەیس
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard let latestApp = importedApps.first else {
                self.statusText = "Error"
                self.stepText = "Failed to locate app"
                return
            }
            
            // مۆرکردنی ڕاستەقینە بەبێ ئێرۆر!
            FR.signPackageFile(
                latestApp,
                using: OptionsManager.shared.options,
                icon: nil,
                certificate: cert
            ) { signError in
                DispatchQueue.main.async {
                    if let error = signError {
                        self.statusText = "Sign Error"
                        self.stepText = error.localizedDescription
                    } else {
                        // گەیشتە ١٠٠٪ و نامەی ئینستاڵی نارد
                        withAnimation { self.progress = 1.0 }
                        self.isCompleted = true
                        self.statusText = "Install Complete"
                        self.stepText = "Completed"
                        NotificationCenter.default.post(name: NSNotification.Name("AshteMobile.installApp"), object: nil)
                    }
                }
            }
        }
    }
}
