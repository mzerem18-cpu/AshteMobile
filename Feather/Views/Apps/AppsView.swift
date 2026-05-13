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
            // پەردەی ئینستاڵکردن
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
            // 💡 لێرەدا fullIconURL بەکارهێنراوە بۆ دەرکەوتنی وێنەکان
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

// پەردەی Signکردنی ڕاستەقینە
struct AppInstallSheetView: View {
    var app: RemoteApp
    @State private var progress: Double = 0.0
    @State private var isCompleted: Bool = false
    @State private var statusText: String = "Preparing Install"
    
    // 💡 هێنانی بڕوانامەکان بە هەمان شێوازی SigningViewـەکەی خۆت
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var certificates: FetchedResults<CertificatePair>
    
    private func selectedCert() -> CertificatePair? {
        let index = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
        guard certificates.indices.contains(index) else { return nil }
        return certificates[index]
    }
    
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
                    
                    if !isCompleted {
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 70 * (1.0 - CGFloat(progress)))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .animation(.spring(), value: progress)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isCompleted ? "Install Complete" : statusText)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(app.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: isCompleted ? "checkmark.square.fill" : "paperplane.fill")
                            .font(.system(size: 12))
                        Text(isCompleted ? "Completed" : "Sending Manifest")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(isCompleted ? .teal : .orange)
                    .padding(.top, 2)
                }
                Spacer()
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(LinearGradient(colors: isCompleted ? [.blue, .cyan] : [.orange, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(progress))
                        .shadow(color: isCompleted ? Color.cyan.opacity(0.4) : Color.purple.opacity(0.4), radius: 6, x: 0, y: 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(isCompleted ? .teal : .orange)
                Spacer()
                Text(isCompleted ? "Ready to open" : "Keep AshteMobile open")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(22)
        .onAppear {
            startRealDownloadAndSign()
        }
    }
    
    func startRealDownloadAndSign() {
        guard let url = URL(string: app.downloadURL) else {
            statusText = "Invalid URL"
            return
        }
        
        statusText = "Downloading..."
        withAnimation(.linear(duration: 2.0)) { progress = 0.5 } // ئەنیمەیشنی داونلۆد
        
        // ١. داونلۆدکردنی فایلی IPA
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                DispatchQueue.main.async { statusText = "Download Failed" }
                return
            }
            
            // ٢. دانانی فایلەکە لە شوێنێکی سەلامەت بۆ Sign
            let fm = FileManager.default
            let tempIpaURL = fm.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).ipa")
            try? fm.removeItem(at: tempIpaURL)
            try? fm.moveItem(at: localURL, to: tempIpaURL)
            
            DispatchQueue.main.async {
                self.statusText = "Signing..."
                withAnimation(.linear(duration: 1.0)) { self.progress = 0.8 }
                
                // ٣. دۆزینەوەی بڕوانامەکە
                guard let cert = self.selectedCert() else {
                    self.statusText = "No Certificate Found!"
                    return
                }
                
                // ٤. دروستکردنی ئۆبجێکتەکە بۆ فەنکشنەکەی خۆت
                let downloadedApp = RemoteDownloadedApp(url: tempIpaURL, name: app.name, version: app.version)
                
                // ٥. بانگکردنی فەنکشنی ڕاستەقینەی Sign لە پڕۆژەکەی خۆت
                FR.signPackageFile(
                    downloadedApp,
                    using: OptionsManager.shared.options,
                    icon: nil,
                    certificate: cert
                ) { signError in
                    DispatchQueue.main.async {
                        if let signError = signError {
                            self.statusText = "Sign Error: \(signError.localizedDescription)"
                        } else {
                            self.statusText = "Sending Manifest..."
                            withAnimation(.linear(duration: 0.5)) { self.progress = 1.0 }
                            
                            // ٦. فەرمانی Install بۆ ئایفۆن
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.isCompleted = true
                                NotificationCenter.default.post(name: Notification.Name("AshteMobile.installApp"), object: nil)
                            }
                        }
                    }
                }
            }
        }
        task.resume()
    }
}

// مۆدێلێکی یارمەتیدەر بۆ ئەوەی FR.signPackageFile بتوانێت IPAـیەکە بخوێنێتەوە
struct RemoteDownloadedApp: AppInfoPresentable {
    var url: URL
    var name: String?
    var identifier: String? = nil
    var version: String?
    var isSigned: Bool { return false }
    var iconData: Data? { return nil }
}
