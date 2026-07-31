import SwiftUI
import WebKit
import UIKit

final class BrowserState: ObservableObject {
    @Published var isClosed = false
    @Published var isLoading = true
    weak var webView: WKWebView?
    func goBack() { if webView?.canGoBack == true { webView?.goBack() } }
    func goForward() { if webView?.canGoForward == true { webView?.goForward() } }
    func goHome() { webView?.load(URLRequest(url: URL(string: "https://tv.p3nd.fun/")!)) }
    func close() { isClosed = true; webView?.stopLoading() }
    func reopen() { isClosed = false; goHome() }
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
        view.load(URLRequest(url: URL(string: "https://tv.p3nd.fun/")!))
        state.webView = view
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) { state.webView = uiView }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let state: BrowserState

        init(state: BrowserState) {
            self.state = state
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            state.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            state.isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            state.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            state.isLoading = false
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
