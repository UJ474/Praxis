import Foundation

enum AppConfiguration {
    static var apiBaseURL: String { UserDefaults.standard.string(forKey: "apiBaseURL") ?? "" }
    static var apiToken: String { UserDefaults.standard.string(forKey: "apiToken") ?? "" }
}
