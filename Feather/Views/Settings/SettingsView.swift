import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

// MARK: - View
struct SettingsView: View {
    @AppStorage("ashtemobile.selectedCert") private var _storedSelectedCert: Int = 0
    @State private var _currentIcon: String? = UIApplication.shared.alternateIconName
    
    // MARK: Fetch
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var _certificates: FetchedResults<CertificatePair>
    
    private var selectedCertificate: CertificatePair? {
        guard
            _storedSelectedCert >= 0,
            _storedSelectedCert < _certificates.count
        else {
            return nil
        }
        return _certificates[_storedSelectedCert]
    }

    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            Form {
                // MARK: - Modern Header (Logo & Social)
                Section {
                    VStack(spacing: 16) {
                        // Profile Image with Modern Shadow
                        AsyncImage(url: URL(string: "https://ashtemobile.site/a.png")) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        } placeholder: {
                            ProgressView()
                                .frame(width: 90, height: 90)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                        .padding(.top, 5)
                        
                        Text("AshteMobile")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        
                        HStack(spacing: 15) {
                            // Telegram Button
                            Button(action: {
                                if let url = URL(string: "https://t.me/ashtemobile") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "paperplane.fill")
                                    Text("Telegram")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(width: 130, height: 40)
                                .background(Color.blue)
                                .clipShape(Capsule())
                                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            
                            // Instagram Button
                            Button(action: {
                                if let url = URL(string: "https://www.instagram.com/ashtemobile") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                    Text("Instagram")
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(width: 130, height: 40)
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [Color.purple, Color.pink, Color.orange]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: Color.pink.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .listRowBackground(Color.clear)

                // MARK: - About & Appearance
                NBSection(.localized("About")) {
                    NavigationLink(destination: AboutView()) {
                        HStack(spacing: 15) {
                            FRAppIconView(size: 32)
                                .frame(width: 32, height: 32)
                                .cornerRadius(8)
                            
                            Text("AshteMobile")
                                .font(.system(size: 17))
                        }
                    }
                    NavigationLink(destination: AppearanceView()) {
                        settingRow(title: .localized("Appearance"), icon: "paintbrush.fill", color: .purple)
                    }
                    NavigationLink(destination: AppIconView(currentIcon: $_currentIcon)) {
                        settingRow(title: .localized("App Icon"), icon: "app.badge.fill", color: .orange)
                    }
                }
                
                // MARK: - Certificates
                NBSection(.localized("Certificates")) {
                    if let cert = selectedCertificate {
                        CertificatesCellView(cert: cert)
                            .padding(.vertical, 4)
                    } else {
                        Text(.localized("No Certificate"))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    NavigationLink(destination: CertificatesView()) {
                        settingRow(title: .localized("Manage Certificates"), icon: "checkmark.seal.fill", color: .green)
                    }
                } footer: {
                    Text(.localized("Add and manage certificates used for signing applications."))
                }
                
                // MARK: - Features
                NBSection(.localized("Features")) {
                    NavigationLink(destination: ConfigurationView()) {
                        settingRow(title: .localized("Signing Options"), icon: "signature", color: .indigo)
                    }
                    NavigationLink(destination: ArchiveView()) {
                        settingRow(title: .localized("Archive & Compression"), icon: "archivebox.fill", color: .brown)
                    }
                    NavigationLink(destination: InstallationView()) {
                        settingRow(title: .localized("Installation"), icon: "arrow.down.circle.fill", color: .cyan)
                    }
                } footer: {
                    Text(.localized("Configure the apps way of installing, its zip compression levels, and custom modifications to apps."))
                }
                
                // MARK: - Reset
                Section {
                    NavigationLink(destination: ResetView()) {
                        settingRow(title: .localized("Reset All Data"), icon: "trash.fill", color: .red)
                    }
                }
            }
        }
    }
    
    // MARK: - Modern Setting Row Helper
    @ViewBuilder
    private func settingRow(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 15) {
            ZStack {
                color
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 32, height: 32)
            .cornerRadius(8)
            
            Text(title)
                .font(.system(size: 17))
        }
    }
}
