import UIKit
import ProgressHUD

// MARK: - UI Blocking
final class UIBlockingProgressHUD {
    private static var window: UIWindow? {
        UIApplication.shared.windows.first
    }
    
    static func show() {
        window?.isUserInteractionEnabled = false
        
        configureAppearance()
        ProgressHUD.animate()
    }
    
    static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }
    
    private static func configureAppearance() {
        ProgressHUD.animationType = .activityIndicator
        ProgressHUD.mediaSize = 40
        ProgressHUD.marginSize = 20
        ProgressHUD.colorAnimation = .gray
    }
}
