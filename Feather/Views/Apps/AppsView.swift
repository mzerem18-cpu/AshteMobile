import SwiftUI
import CoreData

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
                        Text("Error").foregroundColor(.red)
                        Text(error).multilineTextAlignment(.center).padding()
                        Button("Try Again") { viewModel.fetchApps() }
                            .buttonStyle(.borderedProminent)
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
            .sheet(item: $selectedApp) { app in
                AppInstallSheetView(app: app)
                    .presentationDetents([.medium])
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
            } placeholder: {
                Color.gray.opacity(0.3).overlay(Image(systemName: "app.dashed").foregroundColor(.gray))
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.system(size: 16, weight: .bold))
                if let version = app.version { Text("Version \(version)").font(.system(size: 12)).foregroundColor(.secondary) }
                if let desc = app.description { Text(desc).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1) }
            }
            Spacer()
            
            Button(action: onInstall) {
                Text("GET")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

struct AppInstallSheetView: View {
    var app: RemoteApp
    @State private var progress: Double = 0.0
    @State private var isCompleted: Bool = false
    @State private var statusText: String = "Preparing..."
    
    // هێنانی بڕوانامەکان
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var certificates: FetchedResults<CertificatePair>
    
    private func _selectedCert() -> CertificatePair? {
        let storedCert = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
        guard certificates.indices.contains(storedCert) else { return nil }
        return certificates[storedCert]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                AsyncImage(url: app.fullIconURL) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: { Color.gray.opacity(0.3) }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isCompleted ? "Success!" : statusText)
                        .font(.system(size: 20, weight: .bold))
                    Text(app.name).foregroundColor(.secondary)
                }
                Spacer()
            }
            
            ProgressView(value: progress)
                .tint(isCompleted ? .green : .blue)
            
            if isCompleted {
                Text("App m مۆرکرا و ئامادەیە بۆ ئینستاڵ")
                    .font(.caption).foregroundColor(.green)
            }
        }
        .padding(30)
        .onAppear { startRealSigningProcess() }
    }
    
    // لێرەدا پرۆسەی مۆرکردنی ڕاستەقینە دەستپێدەکات
    func startRealSigningProcess() {
        guard let cert = _selectedCert() else {
            statusText = "تکایە سەرەتا شەهادەیەک هەڵبژێرە"
            return
        }
        
        statusText = "Downloading IPA..."
        progress = 0.1
        
        guard let url = URL(string: app.downloadURL) else { return }
        
        // ١. داونلۆدکردنی فایلەکە
        URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL else {
                DispatchQueue.main.async { statusText = "Download Failed" }
                return
            }
            
            // دروستکردنی فۆڵدەرێکی کاتی
            let fm = FileManager.default
            let tempURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
            try? fm.moveItem(at: localURL, to: tempURL)
            
            DispatchQueue.main.async {
                statusText = "Signing App..."
                progress = 0.5
                
                // ٢. دروستکردنی ئۆبجێکتی ئەپ بۆ مۆرکردن
                // تێبینی: دەبێت RemoteDownloadedApp کە پێشتر دروستمان کرد لێرەدا بەکاربێت
                let downloadedApp = RemoteDownloadedApp(url: tempURL, name: app.name, version: app.version)
                
                // ٣. بانگکردنی فەنکشنی مۆرکردنی ڕاستەقینەی بەرنامەکەت
                FR.signPackageFile(
                    downloadedApp,
                    using: OptionsManager.shared.options,
                    icon: nil,
                    certificate: cert
                ) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            statusText = "Error: \(error.localizedDescription)"
                        } else {
                            progress = 1.0
                            isCompleted = true
                            statusText = "Signed Successfully"
                            
                            // ٤. ناردنی نۆتیفیکەیشنی ئینستاڵکردن بۆ ئەوەی پەنجەرەی ئایفۆن دەرکەوێت
                            NotificationCenter.default.post(name: NSNotification.Name("AshteMobile.installApp"), object: nil)
                        }
                    }
                }
            }
        }.resume()
    }
}

// پێویستە ئەم مۆدێلە لە خوارەوەی هەمان فایل بێت
struct RemoteDownloadedApp: AppInfoPresentable {
    var url: URL
    var name: String?
    var identifier: String? = nil
    var version: String?
    var isSigned: Bool { return false }
    var iconData: Data? { return nil }
}
