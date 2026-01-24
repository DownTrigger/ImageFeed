import UIKit
import ProgressHUD

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
        ProgressHUD.colorHUD = .white
        ProgressHUD.colorAnimation = .black
        ProgressHUD.mediaSize = 40
        ProgressHUD.marginSize = 20
    }
}
