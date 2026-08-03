import SwiftUI
import WebKit

struct ContentView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @StateObject private var browser = BrowserState()

    var body: some View {
        ZStack(alignment: .bottom) {
            if browser.isClosed {
                VStack(spacing: 16) {
                    Image(systemName: "tv.slash").font(.system(size: 46)).foregroundStyle(.cyan)
                    Text("تم إغلاق المشغل").font(.title3.bold())
                    Button("فتح التطبيق") { browser.reopen() }.buttonStyle(.borderedProminent)
                }
            } else {
                ZStack {
                    TVWebView(state: browser)
                        .ignoresSafeArea(edges: .top)

                    if let errorMessage = browser.errorMessage {
                        errorCard(message: errorMessage)
                            .padding(.horizontal, 20)
                    }
                }
            }

            if !browser.isClosed {
                if browser.isLoading {
                    loadingOverlay
                } else {
                    HStack(spacing: 12) {
                        actionButton("chevron.right", "رجوع") { browser.goBack() }
                        actionButton("chevron.left", "التالي") { browser.goForward() }
                        actionButton("house.fill", "الرئيسية") { browser.goHome() }
                        actionButton("arrow.clockwise", "إعادة تحميل") { browser.reload() }
                        actionButton("xmark", "إغلاق") { browser.close() }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 18)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(isPresented: Binding(get: { !hasSeenWelcome }, set: { if !$0 { hasSeenWelcome = true } })) {
            WelcomeView(onStart: { hasSeenWelcome = true })
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
    }

    private func actionButton(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .labelStyle(.iconOnly)
                .frame(width: 42, height: 42)
        }
        .tint(.white)
        .accessibilityLabel(title)
    }

    /// نعرض شريط التحميل بدل أزرار التنقل أثناء تحميل الموقع.
    private var loadingOverlay: some View {
        VStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.cyan)

            Text("جارٍ تحميل الموقع...")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 280)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }

    /// بطاقة خطأ عربية واضحة مع إمكانية إعادة المحاولة بسرعة.
    private func errorCard(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 28))
                .foregroundStyle(.cyan)

            Text("تعذر تحميل الصفحة")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("إعادة محاولة") {
                browser.retry()
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
        .padding(20)
        .frame(maxWidth: 340)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
    }
}

private struct WelcomeView: View {
    let onStart: () -> Void
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "tv.inset.filled")
                .font(.system(size: 50))
                .foregroundStyle(.cyan)
            Text("مرحبًا بك في TV P3ND")
                .font(.title2.bold())
            Text("استمتع بمشاهدة القنوات بسهولة. اسحب داخل الموقع للتصفح، ودوّر الشاشة لملء المشغل.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("دخول") { onStart() }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .controlSize(.large)
        }
        .padding(30)
        .environment(\.layoutDirection, .rightToLeft)
    }
}
