//  UIBlockingProgressHUD.swift

import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        return UIApplication.shared.connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
    }
    
    @MainActor static func show() {
        window?.isUserInteractionEnabled = false
        ProgressHUD.animate()
    }
    
    @MainActor static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }
}
