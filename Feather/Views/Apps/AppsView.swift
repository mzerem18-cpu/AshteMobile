import SwiftUI
import CoreData
import Foundation

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
    
    // کۆنترۆڵکەری داونلۆد کە قەبارە (MB) دەخوێنێتەوە
    @StateObject private var downloader = AppDownloader()
    @State private var isSigning = false
    @State private var signingProgress = 0.0
    
    // هێنانی شەهادەکان لەناو داتابەیس
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
                
                // لێرەدا ڕاستەوخۆ مێگابایتەکانی داونلۆد نیشان دەدات!
                if downloader.isDownloading {
                    Text(downloader.statusText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.blue)
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
                if !downloader.isDownloading && !isSigning {
                    startProcess()
                }
            }) {
                ZStack {
                    if downloader.isDownloading || isSigning {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: 28, height: 28)
                        
                        Circle()
                            // ڕەنگی شین بۆ داونلۆد، ڕەنگی پرتەقاڵی بۆ Sign
                            .trim(from: 0, to: isSigning ? signingProgress : downloader.progress)
                            .stroke(isSigning ? Color.orange : Color.blue, lineWidth: 3)
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
    
    // پرۆسەی سەرەکی (داونلۆد -> مۆرکردن -> ئینستاڵ)
    func startProcess() {
        let selectedIndex = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
        guard certificates.indices.contains(selectedIndex) else { return }
        let cert = certificates[selectedIndex]
        
        guard let url = URL(string: app.downloadURL) else { return }
        
        // ١. دەستپێکردنی داونلۆد بە خوێندنەوەی قەبارە (MB)
        downloader.download(url: url, sizeStr: app.size ?? "Unknown") { localURL in
            guard let localURL = localURL else { return }
            
            isSigning = true
            withAnimation { signingProgress = 0.5 }
            
            // ٢. دروستکردنی مۆدێلە ڕاستەقینەکە بێ ئێرۆر
            let downloadedApp = RemoteDownloadedApp(
                uuid: UUID().uuidString,
                name: app.name,
                version: app.version,
                identifier: nil,
                minOSVersion: nil,
                url: localURL,
                iconData: nil,
                isSigned: false
            )
            
            // ٣. مۆرکردنی ڕاستەقینە بە شەهادەکە
            FR.signPackageFile(
                downloadedApp,
                using: OptionsManager.shared.options,
                icon: nil,
                certificate: cert
            ) { signError in
                DispatchQueue.main.async {
                    withAnimation { signingProgress = 1.0 }
                    
                    if signError == nil {
                        // ٤. ناردنی فەرمانی Install بۆ ئایفۆن!
                        NotificationCenter.default.post(name: NSNotification.Name("AshteMobile.installApp"), object: nil)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isSigning = false
                        signingProgress = 0.0
                    }
                }
            }
        }
    }
}

// MARK: - سیستەمی داونلۆدی ڕاستەقینە بۆ خوێندنەوەی MB
class AppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: Double = 0.0
    @Published var statusText: String = ""
    @Published var isDownloading = false
    
    var completion: ((URL?) -> Void)?
    var expectedSize: String = ""
    
    func download(url: URL, sizeStr: String, completion: @escaping (URL?) -> Void) {
        self.completion = completion
        self.expectedSize = sizeStr
        self.isDownloading = true
        self.progress = 0.0
        self.statusText = "0 MB / \(sizeStr)"
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.downloadTask(with: url).resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async {
            let mbWritten = Double(totalBytesWritten) / 1048576.0
            
            if totalBytesExpectedToWrite > 0 {
                self.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                self.statusText = String(format: "%.1f MB / %@", mbWritten, self.expectedSize)
            } else {
                // ئەگەر قەبارەی کۆتایی نەزاندرا، تەنها MB دابەزیوەکە نیشان دەدات
                self.statusText = String(format: "%.1f MB / %@", mbWritten, self.expectedSize)
                self.progress += 0.01
                if self.progress > 0.9 { self.progress = 0.1 }
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
        try? FileManager.default.moveItem(at: location, to: tempURL)
        
        DispatchQueue.main.async {
            self.isDownloading = false
            self.completion?(tempURL)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let _ = error {
            DispatchQueue.main.async {
                self.statusText = "Error!"
                self.isDownloading = false
                self.completion?(nil)
            }
        }
    }
}

// MARK: - مۆدێلی تەواو (بۆ ئەوەی هەرگیز Error 65 نەداتەوە)
struct RemoteDownloadedApp: AppInfoPresentable {
    var uuid: String?
    var name: String?
    var version: String?
    var identifier: String?
    var minOSVersion: String?
    var url: URL?
    var iconData: Data?
    var isSigned: Bool
}
