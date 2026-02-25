import UIKit
import ProgressHUD

final class UIBlockingProgressHUD {

    // MARK: - Private
    private static var window: UIWindow? {
        UIApplication.shared.windows.first
    }

    private static func configureAppearance() {
        ProgressHUD.animationType = .activityIndicator
        ProgressHUD.colorHUD = .white
        ProgressHUD.colorAnimation = .black
        ProgressHUD.mediaSize = 40
        ProgressHUD.marginSize = 20
    }

    // MARK: - Public API
    static func show() {
        window?.isUserInteractionEnabled = false
        
        configureAppearance()
        ProgressHUD.animate()
    }
    
    static func dismiss() {
        window?.isUserInteractionEnabled = true
        ProgressHUD.dismiss()
    }
}
