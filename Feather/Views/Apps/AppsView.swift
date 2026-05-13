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
                        Text("Error").foregroundColor(.red)
                        Text(error).multilineTextAlignment(.center).padding()
                        Button("Try Again") { viewModel.fetchApps() }
                            .buttonStyle(.borderedProminent)
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
    
    // ستەیتەکان بۆ کۆنترۆڵکردنی دوگمەکە
    @State private var isDownloading = false
    @State private var progress: Double = 0.0
    @State private var statusText: String = ""
    
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var certificates: FetchedResults<CertificatePair>

    var body: some View {
        HStack(spacing: 15) {
            // وێنەی ئەپەکە
            AsyncImage(url: app.fullIconURL) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.gray.opacity(0.3).overlay(Image(systemName: "app.dashed").foregroundColor(.gray))
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.system(size: 16, weight: .bold))
                
                if isDownloading {
                    // نیشاندانی مێگابایت یان ڕێژەی سەدی لە کاتی داونلۆد
                    Text(statusText)
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                } else {
                    if let version = app.version {
                        Text("Version \(version)").font(.system(size: 12)).foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // دوگمەی GET کە دەگۆڕێت بۆ بازنەی بارگاویبوون
            Button(action: {
                if !isDownloading {
                    startFastInstall()
                }
            }) {
                ZStack {
                    if isDownloading {
                        // بازنەی سووڕاوە (Loading)
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 3)
                            .frame(width: 32, height: 32)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.blue, lineWidth: 3)
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))
                    } else {
                        Text("GET")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }
            .disabled(isDownloading)
        }
        .padding(.vertical, 4)
    }
    
    // فەنکشنی مۆرکردن و ئینستاڵکردنی ڕاستەوخۆ
    func startFastInstall() {
        // ١. دڵنیابوونەوە لە هەبوونی شەهادە
        let storedCert = UserDefaults.standard.integer(forKey: "ashtemobile.selectedCert")
        guard certificates.indices.contains(storedCert) else {
            // ئەگەر شەهادەی نەبوو
            return
        }
        let cert = certificates[storedCert]
        
        isDownloading = true
        statusText = "Waiting..."
        
        // ئەمە تەنها ئەنیمەیشنە بۆ ئەوەی Build سەرکەوتوو بێت و نیشانی بدەیت
        // لەم قۆناغەدا تەنها ئەنیمەیشنەکە دەبینیت
        withAnimation(.linear(duration: 0.5)) {
            progress = 0.2
            statusText = "0% / \(app.size ?? "")"
        }
        
        // لاساییکردنەوەی داونلۆد و مۆرکردن (Simulation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                progress = 0.6
                statusText = "Signing..."
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    progress = 1.0
                    statusText = "Installing..."
                }
                
                // بانگکردنی فەرمانی ئینستاڵکردنی ئەپڵ (Popup)
                NotificationCenter.default.post(name: NSNotification.Name("AshteMobile.installApp"), object: nil)
                
                // دوای ماوەیەک دوگمەکە دەگەڕێتەوە باری ئاسایی
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isDownloading = false
                    progress = 0
                }
            }
        }
    }
}
