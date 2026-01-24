import UIKit
import Logging

final class AlertPresenter {
    
    // MARK: - Logger
    private static let logger = Logger(label: "AlertPresenter")
    
    // MARK: - Public API
    static func showAuthErrorAlert(on viewController: UIViewController, onDismiss: @escaping () -> Void) {
        logger.info("[showAuthErrorAlert]: show alert")
        
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        
        let action = UIAlertAction(title: "ОК", style: .default) { _ in
            onDismiss()
        }
        
        alert.addAction(action)
        presentAlert(alert, on: viewController)
    }
    
    static func showImageLoadAlert(
        on viewController: UIViewController,
        onRetry: @escaping () -> Void
    ) {
        logger.info("[showImageLoadAlert]: show alert")
        
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
        
        presentAlert(alert, on: viewController)
    }
    
    static func showLogoutConfirmationAlert(
        on viewController: UIViewController,
        onConfirm: @escaping () -> Void
    ) {
        logger.info("[showLogoutConfirmationAlert]: show alert")
        
        let alert = UIAlertController(
            title: "Выход из аккаунта",
            message: "Вы уверены, что хотите выйти?",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Отмена", style: .cancel)
        let logoutAction = UIAlertAction(title: "Выйти", style: .destructive) { _ in
            onConfirm()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(logoutAction)
        
        presentAlert(alert, on: viewController)
    }
    
    // MARK: - Helpers
    private static func presentAlert(_ alert: UIAlertController, on viewController: UIViewController) {
        viewController.present(alert, animated: true)
    }
}
