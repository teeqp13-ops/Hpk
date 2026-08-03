import SwiftUI
import WebKit
import UIKit

final class BrowserState: ObservableObject {
    @Published var isClosed = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    weak var webView: WKWebView?

    func attachWebView(_ webView: WKWebView) {
        self.webView = webView
    }

    func goBack() {
        guard webView?.canGoBack == true else { return }
        errorMessage = nil
        webView?.goBack()
    }

    func goForward() {
        guard webView?.canGoForward == true else { return }
        errorMessage = nil
        webView?.goForward()
    }

    func goHome() {
        errorMessage = nil
        guard let request = TVP3NDConstants.makeHomeRequest() else {
            presentConfigurationError()
            return
        }

        guard let webView else { return }
        isLoading = true
        webView.load(request)
    }

    func reload() {
        errorMessage = nil

        guard let webView else { return }
        isLoading = true

        if webView.url == nil {
            goHome()
        } else {
            webView.reload()
        }
    }

    func retry() {
        if webView?.url == nil {
            goHome()
        } else {
            reload()
        }
    }

    func close() {
        isClosed = true
        isLoading = false
        errorMessage = nil
        webView?.stopLoading()
    }

    func reopen() {
        isClosed = false
        isLoading = false
        errorMessage = nil
    }

    func handleNavigationStarted() {
        isLoading = true
        errorMessage = nil
    }

    func handleNavigationFinished() {
        isLoading = false
        errorMessage = nil
    }

    func handleNavigationFailure(_ error: Error) {
        let nsError = error as NSError

        guard !isClosed else { return }

        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }

        if nsError.domain == WKError.errorDomain && nsError.code == WKError.Code.webViewInvalidated.rawValue {
            return
        }

        isLoading = false
        errorMessage = userFacingMessage(for: nsError)
    }

    private func presentConfigurationError() {
        isLoading = false
        errorMessage = "تعذر تهيئة رابط التطبيق حالياً. يرجى المحاولة لاحقاً."
    }

    /// تحويل أخطاء الشبكة إلى رسائل عربية واضحة للمستخدم.
    private func userFacingMessage(for error: NSError) -> String {
        guard error.domain == NSURLErrorDomain else {
            if error.domain == WKError.errorDomain,
               error.code == WKError.Code.webContentProcessTerminated.rawValue {
                return "تمت إعادة تشغيل محتوى الصفحة. يمكنك إعادة المحاولة الآن."
            }

            return "حدث خطأ غير متوقع أثناء تحميل الصفحة. حاول مرة أخرى."
        }

        switch error.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return "لا يوجد اتصال بالإنترنت حالياً. تأكد من الشبكة ثم أعد المحاولة."
        case NSURLErrorTimedOut:
            return "انتهت مهلة الاتصال بالموقع. حاول مرة أخرى بعد قليل."
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed:
            return "تعذر الوصول إلى الخادم حالياً. حاول مرة أخرى لاحقاً."
        case NSURLErrorSecureConnectionFailed,
             NSURLErrorServerCertificateHasBadDate,
             NSURLErrorServerCertificateUntrusted,
             NSURLErrorServerCertificateHasUnknownRoot,
             NSURLErrorServerCertificateNotYetValid:
            return "تعذر إنشاء اتصال آمن بالموقع. حاول مرة أخرى لاحقاً."
        default:
            return "تعذر تحميل الصفحة الآن. حاول إعادة التحميل أو تحقق من اتصالك."
        }
    }
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
        state.attachWebView(view)
        state.goHome()
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        state.attachWebView(uiView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let state: BrowserState

        init(state: BrowserState) {
            self.state = state
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { return decisionHandler(.cancel) }
            let allowedHost = url.host == TVP3NDConstants.primaryHost || url.host?.hasSuffix(TVP3NDConstants.allowedHostSuffix) == true

            if allowedHost || url.scheme == "about" {
                decisionHandler(.allow)
            } else if ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.cancel)
            }
        }

        /// نحدّث حالة الواجهة لعرض مؤشر التحميل وإخفاء الرسائل القديمة.
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            state.handleNavigationStarted()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            state.handleNavigationFinished()
        }

        /// فشل تحميل أولي غالباً يكون بسبب الشبكة أو المهلة أو الشهادة.
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            state.handleNavigationFailure(error)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            state.handleNavigationFailure(error)
        }
    }
}
