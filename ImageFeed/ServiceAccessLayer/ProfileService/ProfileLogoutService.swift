// ProfileLogoutService.swift

import UIKit
import WebKit

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    private init() {}
    
    func logout() {
        OAuth2TokenStorage.shared.token = nil
        
        cleanCookies()
        resetProfileData()
        showAuthScreen()
    }
    
    private func resetProfileData() {
        ProfileService.shared.resetProfile()
        ProfileImageService.shared.resetAvatarURL()
        ImageListService.shared.resetPhotos()
        
    }
    
    private func cleanCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    
    private func showAuthScreen() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let authVC = storyboard.instantiateViewController(withIdentifier: "AuthViewController")
        
        window.rootViewController = authVC
        window.makeKeyAndVisible()
        UIView.transition(with: window,
                          duration: 0.5,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
    }
}
