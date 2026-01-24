import UIKit

final class AlertPresenter {
    
    static func showAuthErrorAlert(on viewController: UIViewController, onDismiss: @escaping () -> Void) {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        
        let action = UIAlertAction(title: "ОК", style: .default){ _ in
            onDismiss()
        }
        
        alert.addAction(action)
        viewController.present(alert, animated: true)
    }
    
    static func showImageLoadAlert(
        on viewController: UIViewController,
        onRetry: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: "Что-то пошло не так",
            message: "Попробовать ещё раз?",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Не надо", style: .cancel)
        
        let retryAction = UIAlertAction(title: "Повторить", style: .default) { _ in
            onRetry()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(retryAction)
        
        viewController.present(alert, animated: true)
    }
    
}
