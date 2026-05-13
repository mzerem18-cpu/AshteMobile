//
//  TabEnum.swift
//  ashtemobile
//
//  Modified for AshteMobile
//

import SwiftUI
import NimbleViews

enum TabEnum: String, CaseIterable, Hashable {
    case home        
    case apps        // 💡 ١. زیادکردنی بەشی ئەپەکان بێ دەستکاریکردنی ئەوانی تر
    case sources
    case library
    case settings
    case certificates
    
    var title: String {
        switch self {
        case .home:         return .localized("Home") 
        case .apps:         return "Apps" // 💡 ٢. ناوی بەشەکە
        case .sources:      return .localized("Sources")
        case .library:      return .localized("Library")
        case .settings:     return .localized("Settings")
        case .certificates: return .localized("Certificates")
        }
    }
    
    var icon: String {
        switch self {
        case .home:         return "house.fill" 
        case .apps:         return "square.grid.2x2.fill" // 💡 ٣. ئایکۆنی بەشی ئەپەکان
        case .sources:      return "globe.desk"
        case .library:      return "square.grid.2x2"
        case .settings:     return "gearshape.2"
        case .certificates: return "person.text.rectangle"
        }
    }
    
    @ViewBuilder
    static func view(for tab: TabEnum) -> some View {
        switch tab {
        case .home:         HomeView() 
        case .apps:         AppsView() // 💡 ٤. بانگکردنی فایلە نوێیەکەی خۆمان
        case .sources:      SourcesView()
        case .library:      LibraryView()
        case .settings:     SettingsView()
        case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
        }
    }
    
    static var defaultTabs: [TabEnum] {
        return [
            .home,    
            .apps,    // 💡 ٥. داماننا لە تەنیشت Home لە خوارەوەی شاشەکە
            .sources,
            .library,
            .settings
        ]
    }
    
    static var customizableTabs: [TabEnum] {
        return [
            .certificates
        ]
    }
}
