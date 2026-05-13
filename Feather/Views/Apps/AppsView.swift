import SwiftUI
import IDeviceSwift

struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    
    // کۆنترۆڵکردنی پەردەی داونلۆد (Sheet)
    @State private var selectedApp: RemoteApp?
    @StateObject private var installerViewModel = InstallerStatusViewModel()
    
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
                            // کاتێک کلیک لە GET دەکرێت، ئەم ئەپە هەڵدەبژێردرێت
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
            // 💡 هێنانی پەردە شازەکە بۆ سەر شاشە بێ گۆڕینی پەڕە
            .sheet(item: $selectedApp) { app in
                InstallProgressView(app: app, viewModel: installerViewModel)
                    .presentationDetents([.medium])
                    .onAppear {
                        // هەر کە پەردەکە دەرکەوت، داونلۆد و مۆرکردن دەست پێدەکات
                        startSilentDownloadAndSign(for: app)
                    }
            }
        }
    }
    
    func startSilentDownloadAndSign(for app: RemoteApp) {
        // سفرکردنەوەی دۆخی پێشکەوتن
        installerViewModel.overallProgress = 0.0
        installerViewModel.isCompleted = false
        installerViewModel.status = "Downloading \(app.name)..."
        
        guard let downloadURL = URL(string: app.downloadURL) else { return }
        
        // داونلۆدکردنی IPA بە بێدەنگی
        let task = URLSession.shared.downloadTask(with: downloadURL) { localURL, response, error in
            guard let localURL = localURL else { return }
            
            DispatchQueue.main.async {
                installerViewModel.overallProgress = 0.5
                installerViewModel.status = "Signing with your certificate..."
                
                // ⚠️ تێبینی ئەندازیار: لێرەدا دەبێت کۆدی Signکردنەکەی خۆت بانگ بکەیت
                // نموونەی ئەوەی کە دەبێت تۆ بینووسیت (بەپێی کۆدی خۆت دەگۆڕێت):
                /*
                SignManager.shared.signApp(at: localURL) { success, signedFile in
                    if success {
                        installerViewModel.overallProgress = 1.0
                        installerViewModel.isCompleted = true
                        installerViewModel.status = "Install Complete"
                        
                        // فەرمانی ئینستاڵکردن (دەرهێنانی پاپ-ئەپی ئەپڵ)
                        InstallManager.install(signedFile)
                    }
                }
                */
                
                // 💡 ئەم چەند دێڕەی خوارەوەم تەنها بۆ تاقیکردنەوەی دیزاینەکە داناوە، کاتێک کۆدی Signـی خۆت دانا، ئەمەی خوارەوە بسڕەوە:
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    installerViewModel.overallProgress = 1.0
                    installerViewModel.isCompleted = true
                }
            }
        }
        task.resume()
    }
}

// 💡 دیزاینی هەر یەکێک لە ئەپەکان لەناو لیستەکەدا
struct AppRowView: View {
    var app: RemoteApp
    var onInstall: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: URL(string: app.iconURL ?? "")) { image in
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
