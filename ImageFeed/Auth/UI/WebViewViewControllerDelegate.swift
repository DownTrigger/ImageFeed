import Foundation

protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(
        _ viewController: WebViewViewController,
        didAuthenticateWithCode code: String
    )
}
