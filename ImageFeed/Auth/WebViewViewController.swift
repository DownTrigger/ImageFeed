import UIKit
import WebKit

// MARK: - Constants
enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
    static let redirectPath = "/oauth/authorize/native"
}

// MARK: - Delegate
protocol WebViewViewControllerDelegate: AnyObject {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

// MARK: - WebViewViewController
final class WebViewViewController: UIViewController {
    
    // MARK: Outlets
    @IBOutlet private var webView: WKWebView!
    @IBOutlet private var progressView: UIProgressView!
    
    // MARK: Dependencies
    weak var delegate: WebViewViewControllerDelegate?
    
    // MARK: Private properties
    private var progressObservation: NSKeyValueObservation?
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureWebView()
        loadAuthPage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeWebViewProgress()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        progressObservation = nil
    }
    
}

// MARK: - WKNavigationDelegate
extension WebViewViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let code = extractCode(from: navigationAction) {
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
}

// MARK: - Private helpers
extension WebViewViewController {
    
    private func configureWebView() {
        webView.navigationDelegate = self
    }
    
    private func loadAuthPage() {
        guard var components = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
            assertionFailure("WebViewViewController: failed to create URLComponents")
            return
        }
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
        
        guard let url = components.url else {
            assertionFailure("WebViewViewController: failed to build auth URL")
            return
        }
        
        webView.load(URLRequest(url: url))
        updateProgress(0)
    }
    
    private func observeWebViewProgress() {
        progressObservation = webView.observe(
            \.estimatedProgress,
             options: [.new]
        ) { [weak self] webView, _ in
            self?.updateProgress(webView.estimatedProgress)
        }
    }
    
    private func updateProgress(_ progress: Double) {
        progressView.progress = Float(progress)
        progressView.isHidden = abs(progress - 1.0) < 0.0001
    }
    
    private func extractCode(from navigationAction: WKNavigationAction) -> String? {
        guard
            let url = navigationAction.request.url,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.path == WebViewConstants.redirectPath,
            let queryItems = components.queryItems,
            let codeItem = queryItems.first(where: { $0.name == "code" })
        else {
            return nil
        }
        
        return codeItem.value
    }
    
}
