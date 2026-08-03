import Foundation

enum TVP3NDConstants {
    /// الرابط الأساسي للتطبيق لتجنب تكراره في أكثر من مكان.
    static let baseURLString = "https://tv.p3nd.fun/"
    static let requestTimeout: TimeInterval = 30
    static let primaryHost = "tv.p3nd.fun"
    static let allowedHostSuffix = ".p3nd.fun"

    /// ننشئ الطلب في مكان مركزي مع مهلة تحميل واضحة.
    static func makeHomeRequest() -> URLRequest? {
        guard let url = URL(string: baseURLString) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = requestTimeout
        return request
    }
}
