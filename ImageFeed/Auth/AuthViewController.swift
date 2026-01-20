import UIKit
import Logging

// MARK: - AuthViewControllerDelegate
protocol AuthViewControllerDelegate: AnyObject {
    func authViewController(_ vc: AuthViewController, didReceiveCode code: String)
}

// MARK: - AuthViewController
final class AuthViewController: UIViewController {
    
    // MARK: Constants
    private let showWebViewSegueIdentifier = "ShowWebView"
    
    // MARK: - Logger
    private let logger = Logger(label: "AuthViewController")
    
    // MARK: - Public properties
    weak var delegate: AuthViewControllerDelegate?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackButton()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            segue.destination.modalPresentationStyle = .fullScreen
            
            guard
                let webViewViewController = segue.destination as? WebViewViewController
            else {
                // self.logger.error("[AuthViewController.prepare]: Error – invalid destination for ShowWebView segue")
                print("[AuthViewController.prepare]: Error – invalid destination for ShowWebView segue")
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
        vc.dismiss(animated: true)
        delegate?.authViewController(self, didReceiveCode: code)
    }
    
    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
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
