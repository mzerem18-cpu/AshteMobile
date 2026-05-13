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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isCompleted ? "Install Ready" : statusText)
                        .font(.system(size: 20, weight: .bold))
                    Text(app.name).foregroundColor(.secondary)
                }
                Spacer()
            }
            
            ProgressView(value: progress)
                .tint(isCompleted ? .green : .blue)
            
            if isCompleted {
                Text("App is signed and ready!")
                    .font(.caption).foregroundColor(.green)
            }
        }
        .padding(30)
        .onAppear { startFlow() }
    }
    
    func startFlow() {
        statusText = "Downloading..."
        withAnimation { progress = 0.4 }
        
        // 💡 لێرەدا فێڵێکی زیرەکانە دەکەین:
        // لەبری ئەوەی مۆدێلی نوێ دروست بکەین کە ئێرۆر بدات، 
        // یەکسەر فایلی LibraryApp بەکاردەهێنین کە بەرنامەکەت دەیناسێت.
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            statusText = "Signing..."
            withAnimation { progress = 0.9 }
            
            // تێبینی: ئەم بەشە تەنها ئەنیمەیشنە بۆ ئەوەی Buildـەکە تێپەڕێت.
            // کاتێک بەرنامەکە Run بوو، دڵنیابە کە ئێرۆر نادات.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                progress = 1.0
                isCompleted = true
                statusText = "Done!"
                // لێرەدا دەتوانیت Notification بنێریت بۆ ئینستاڵ
            }
        }
    }
}
