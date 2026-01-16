import UIKit

// MARK: - AuthViewControllerDelegate
protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

// MARK: - AuthViewController
final class AuthViewController: UIViewController {
    
    // MARK: Constants
    private let showWebViewSegueIdentifier = "ShowWebView"
    
    // MARK: Dependencies
    private let oauth2Service = OAuth2Service.shared
    
    // MARK: Public properties
    weak var delegate: AuthViewControllerDelegate?
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard
                let webViewViewController = segue.destination as? WebViewViewController
            else {
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
                return
            }
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
    
}

// MARK: - WebViewViewControllerDelegate
extension AuthViewController: WebViewViewControllerDelegate {
    
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        fetchOAuthToken(code)
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
    
}

// MARK: - OAuth logic
extension AuthViewController {
    
    private func fetchOAuthToken(_ code: String) {
        oauth2Service.fetchAuthToken(code) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success:
                self.switchToMainScreen()
            case .failure:
                // TODO обработка ошибки
                break
            }
        }
    }
    
}

// MARK: - Routing
extension AuthViewController {
    
    private func switchToMainScreen() {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let sceneDelegate = windowScene.delegate as? SceneDelegate,
            let window = sceneDelegate.window
        else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarController = storyboard.instantiateViewController(
            withIdentifier: "TabBarViewController"
        )
        
        guard let snapshot = window.snapshotView(afterScreenUpdates: true) else {
            window.rootViewController = tabBarController
            return
        }
        
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
        
        window.addSubview(snapshot)
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                snapshot.transform = CGAffineTransform(translationX: -window.bounds.width, y: 0)
            },
            completion: { _ in
                snapshot.removeFromSuperview()
            }
        )
    }
    
}

// MARK: - UI configuration
extension AuthViewController {
    
    private func configureBackButton() {
        navigationController?.navigationBar.backIndicatorImage = UIImage(resource: .iconBackChevronWV)
        navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(resource: .iconBackChevronWV)
        navigationItem.backBarButtonItem = UIBarButtonItem( title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = UIColor(resource: .ypBlack)
    }
    
}


