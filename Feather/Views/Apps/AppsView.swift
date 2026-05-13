import SwiftUI
import CoreData
import Combine

struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    
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
                        AppRowView(app: app)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Apps")
            .onAppear {
                if viewModel.apps.isEmpty { viewModel.fetchApps() }
            }
        }
    }
}

struct AppRowView: View {
    var app: RemoteApp
    
    @ObservedObject var downloadManager = DownloadManager.shared
    @State private var currentDownload: Download? = nil
    @State private var isSigning = false
    
    @State private var progress: Double = 0
    @State private var bytesDownloaded: Int64 = 0
    @State private var totalBytes: Int64 = 0
    @State private var unpackageProgress: Double = 0
    
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

    var overallProgress: Double {
        if let dl = currentDownload {
            return dl.onlyArchiving ? unpackageProgress : (0.3 * unpackageProgress) + (0.7 * progress)
        }
        return 0
    }

    var statusText: String {
        if totalBytes > 0 {
            let mbDownloaded = Double(bytesDownloaded) / 1048576.0
            let mbTotal = Double(totalBytes) / 1048576.0
            return String(format: "%.1f MB / %.1f MB", mbDownloaded, mbTotal)
        } else if bytesDownloaded > 0 {
            let mbDownloaded = Double(bytesDownloaded) / 1048576.0
            return String(format: "%.1f MB", mbDownloaded)
        }
        return "Starting..."
    }

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
                
                if currentDownload != nil {
                    Text(statusText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.blue)
                        .contentTransition(.numericText())
                } else if isSigning {
                    Text("Signing...")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                } else {
                    Text(app.version ?? "Unknown")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                if currentDownload == nil && !isSigning {
                    startNativeDownloadAndSign()
                }
            }) {
                ZStack {
                    if currentDownload != nil || isSigning {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: 28, height: 28)
                        
                        Circle()
                            .trim(from: 0, to: isSigning ? 1.0 : overallProgress)
                            .stroke(isSigning ? Color.orange : Color.blue, lineWidth: 3)
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear, value: overallProgress)
                    } else {
                        Text("GET")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onReceive(timer) { _ in
            if let dl = currentDownload {
                self.progress = dl.progress
                self.bytesDownloaded = dl.bytesDownloaded
                self.totalBytes = dl.totalBytes
                self.unpackageProgress = dl.unpackageProgress
                
                // کاتێک داونلۆد تەواو بوو
                if !downloadManager.manualDownloads.contains(where: { $0 === dl }) {
                    self.currentDownload = nil
                    // دڵنیابوونەوە لەوەی کە بەڕاستی داونلۆد بووە
                    if self.bytesDownloaded > 0 {
                        startSigningLatestImportedApp()
                    } else {
                        self.isSigning = false
                    }
                }
            }
        }
    }
    
    func startNativeDownloadAndSign() {
        let selectedIndex = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
        guard certificates.indices.contains(selectedIndex) else { return }
        
        // 🔥 لێرەدا لینکی شکێنراوی ڕاستەقینە بەکاردەهێنین
        guard let url = app.actualDownloadURL else { return }
        let id = "AshteMobileStore_\(UUID().uuidString)"
        
        if let dl = downloadManager.startDownload(from: url, id: id) as? Download {
            self.currentDownload = dl
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let lastDL = downloadManager.manualDownloads.last {
                    self.currentDownload = lastDL
                }
            }
        }
    }
    
    func startSigningLatestImportedApp() {
        let selectedIndex = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
        guard certificates.indices.contains(selectedIndex) else { return }
        let cert = certificates[selectedIndex]
        
        isSigning = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard let latestApp = importedApps.first else {
                isSigning = false
                return
            }
            
            FR.signPackageFile(
                latestApp,
                using: OptionsManager.shared.options,
                icon: nil,
                certificate: cert
            ) { signError in
                DispatchQueue.main.async {
                    if signError == nil {
                        NotificationCenter.default.post(name: NSNotification.Name("AshteMobile.installApp"), object: nil)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isSigning = false
                    }
                }
            }
        }
    }
}
