import SwiftUI
import WebKit
import UIKit

final class BrowserState: ObservableObject {
    @Published var isClosed = false
    weak var webView: WKWebView?
    func goBack() { if webView?.canGoBack == true { webView?.goBack() } }
    func goForward() { if webView?.canGoForward == true { webView?.goForward() } }
    func goHome() { webView?.load(URLRequest(url: URL(string: "https://tv.p3nd.fun/")!)) }
    func close() { isClosed = true; webView?.stopLoading() }
    func reopen() { isClosed = false; goHome() }
}

struct TVWebView: UIViewRepresentable {
    @ObservedObject var state: BrowserState
    func makeCoordinator() -> Coordinator { Coordinator() }

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
