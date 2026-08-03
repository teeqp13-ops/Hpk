import SwiftUI
import WebKit
import UIKit

final class BrowserState: ObservableObject {
    @Published var isClosed = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    weak var webView: WKWebView?
    func goBack() { if webView?.canGoBack == true { webView?.goBack() } }
    func goForward() { if webView?.canGoForward == true { webView?.goForward() } }
    func goHome() {
        guard let url = URL(string: "https://tv.p3nd.fun/") else { return }
        webView?.load(URLRequest(url: url))
    }
    func close() { isClosed = true; webView?.stopLoading() }
    func reopen() { isClosed = false; goHome() }
    func retry() { errorMessage = nil; goHome() }
}

struct TVWebView: UIViewRepresentable {
    @ObservedObject var state: BrowserState
    func makeCoordinator() -> Coordinator { Coordinator(state: state) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.contentInsetAdjustmentBehavior = .never
        guard let url = URL(string: "https://tv.p3nd.fun/") else { return view }
        view.load(URLRequest(url: url))
        state.webView = view
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { state.webView = uiView }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private weak var state: BrowserState?

        init(state: BrowserState) {
            self.state = state
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.state?.isLoading = true
                self.state?.errorMessage = nil
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.state?.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.state?.isLoading = false
                self.state?.errorMessage = "فشل تحميل الصفحة. يرجى التحقق من اتصالك بالإنترنت."
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.state?.isLoading = false
                self.state?.errorMessage = "تعذّر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى."
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { return decisionHandler(.cancel) }
            let allowedHost = url.host == "tv.p3nd.fun" || url.host?.hasSuffix(".p3nd.fun") == true
            if allowedHost || url.scheme == "about" {
                decisionHandler(.allow)
            } else if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.cancel)
            }
        }
    }
}
