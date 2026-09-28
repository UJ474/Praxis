import Foundation

enum APIError: LocalizedError { case missingConfiguration, badResponse, server(String); var errorDescription: String? { switch self { case .missingConfiguration: "Open Connection Settings and add your Railway URL and API token."; case .badResponse: "The server returned an unexpected response."; case .server(let message): message } } }

struct APIClient {
    // Copy Config.example.swift to Config.swift; Config.swift is deliberately gitignored.
    private var baseURL: String { AppConfiguration.apiBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }
    private var token: String { AppConfiguration.apiToken }
    private let decoder: JSONDecoder = { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d }()
    private let encoder: JSONEncoder = { let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601; return e }()

    func latestNewsletter() async throws -> NewsletterEntry {
        try await request("newsletter/latest", method: "GET")
    }
    func syncNewsletter() async throws -> NewsletterEntry {
        try await request("newsletter/sync", method: "POST")
    }
    func tasks(for weekOf: Date) async throws -> [TaskItem] {
        let date = ISO8601DateFormatter().string(from: weekOf)
        return try await request("tasks?weekOf=\(date)", method: "GET")
    }
    func save(_ task: TaskItem) async throws -> TaskItem {
        try await request("tasks", method: "POST", body: task)
    }
    func update(_ task: TaskItem) async throws -> TaskItem {
        try await request("tasks/\(task.id)", method: "PATCH", body: task)
    }
    func gmailAuthorizationURL() -> URL? { URL(string: baseURL + "/auth/google/start") }
    func healthCheck() async throws {
        guard !baseURL.isEmpty, let url = URL(string: baseURL + "/health") else { throw APIError.missingConfiguration }
        let (_, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw APIError.badResponse }
    }

    private func request<T: Decodable>(_ path: String, method: String, body: (any Encodable)? = nil) async throws -> T {
        guard !baseURL.isEmpty, !token.isEmpty, let url = URL(string: baseURL + "/api/" + path) else { throw APIError.missingConfiguration }
        var request = URLRequest(url: url); request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body { request.httpBody = try encoder.encode(AnyEncodable(body)) }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        guard 200..<300 ~= http.statusCode else {
            let message = (try? JSONDecoder().decode(ServerError.self, from: data).error) ?? "Server error \(http.statusCode)"
            throw APIError.server(message)
        }
        return try decoder.decode(T.self, from: data)
    }
}

private struct ServerError: Decodable { let error: String }

private struct AnyEncodable: Encodable { let encodeClosure: (Encoder) throws -> Void; init(_ value: some Encodable) { encodeClosure = value.encode }; func encode(to encoder: Encoder) throws { try encodeClosure(encoder) } }
