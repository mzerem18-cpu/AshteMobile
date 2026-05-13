import SwiftUI
import CoreData

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
    @State private var isProcessing = false
    @State private var progress: Double = 0.0
    @State private var statusText: String = ""
    
    // هێنانی شەهادەکان لە داتابەیسی بەرنامەکەت
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var certificates: FetchedResults<CertificatePair>

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
                Text(isProcessing ? statusText : (app.version ?? "Unknown Version"))
                    .font(.system(size: 12))
                    .foregroundColor(isProcessing ? .blue : .secondary)
            }
            
            Spacer()
            
            Button(action: { if !isProcessing { startRealInstall() } }) {
                ZStack {
                    if isProcessing {
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.blue, lineWidth: 3)
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))
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
    }
    
    // 🔥 فەنکشنی مۆرکردن و ئینستاڵکردنی ڕاستەقینە
    func startRealInstall() {
        // ١. دۆزینەوەی ئەو شەهادەیەی بەکارهێنەر دیاری کردووە
        let selectedIndex = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
        guard certificates.indices.contains(selectedIndex) else {
            // ئەگەر شەهادەی نەبوو، هیچ مەکە
            return
        }
        let cert = certificates[selectedIndex]
        
        guard let url = URL(string: app.downloadURL) else { return }
        
        isProcessing = true
        statusText = "Downloading..."
        progress = 0.1
        
        // ٢. داونلۆدکردنی فایلی IPA
        URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                DispatchQueue.main.async { isProcessing = false }
                return
            }
            
            // گواستنەوەی فایل بۆ فۆڵدەرێکی کاتی
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
            try? FileManager.default.moveItem(at: localURL, to: tempURL)
            
            DispatchQueue.main.async {
                statusText = "Signing..."
                progress = 0.6
                
                // ٣. مۆرکردنی فایلەکە بە فەنکشنی ئەسڵی بەرنامەکەت
                let downloadedApp = RemoteDownloadedApp(url: tempURL, name: app.name, version: app.version)
                
                FR.signPackageFile(
                    downloadedApp,
                    using: OptionsManager.shared.options,
                    icon: nil,
                    certificate: cert
                ) { signError in
                    DispatchQueue.main.async {
                        if signError == nil {
                            progress = 1.0
                            statusText = "Installing..."
                            
                            // ٤. ناردنی نۆتیفیکەیشنی ئینستاڵ (کە پەنجەرەی ئەپڵ دەهێنێت)
                            NotificationCenter.default.post(name: NSNotification.Name("AshteMobile.installApp"), object: nil)
                        }
                        
                        // دوای ٥ چرکە دوگمەکە ئاسایی بکەرەوە
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            isProcessing = false
                            progress = 0
                        }
                    }
                }
            }
        }.resume()
    }
}

// مۆدێلێکی یارمەتیدەر بۆ ئەوەی لەگەڵ پڕۆژەکەت بگونجێت
struct RemoteDownloadedApp: AppInfoPresentable {
    var url: URL
    var name: String?
    var identifier: String? = nil
    var version: String?
    var isSigned: Bool { return false }
    var iconData: Data? { return nil }
}
