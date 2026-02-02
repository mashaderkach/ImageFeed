//  OAuth2TokenStorage.swift

import Foundation

final class OAuth2TokenStorage {
    
    private let tokenKey = "oauthToken"
    
    var token: String? {
        get {
            UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: tokenKey)
        }
    }
}
