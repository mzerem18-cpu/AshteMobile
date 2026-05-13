import SwiftUI

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

// دیزاینی یارییەکان لە لیستەکەدا
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

// دیزاینە شازەکەی Ksign بە سەربەخۆیی (بۆ ئەوەی ئێرۆر نەدات)
struct AppInstallSheetView: View {
    var app: RemoteApp
    @State private var progress: Double = 0.0
    @State private var isCompleted: Bool = false
    @State private var statusText: String = "Preparing Install"
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                ZStack(alignment: .trailing) {
                    AsyncImage(url: URL(string: app.iconURL ?? "")) { image in
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
            startSimulation()
        }
    }
    
    // لێرەدا دواتر کۆدی Sign کردنەکەی خۆت دادەنێین، ئێستا تەنها ئەنیمەیشنە
    func startSimulation() {
        statusText = "Downloading..."
        withAnimation(.linear(duration: 2.0)) { progress = 0.5 }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            statusText = "Signing with certificate..."
            withAnimation(.linear(duration: 2.0)) { progress = 1.0 }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                isCompleted = true
            }
        }
    }
}
