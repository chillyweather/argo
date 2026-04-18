import Foundation

final class AuthURLProtocol: URLProtocol {
    static var token: String = ""

    override class func canInit(with request: URLRequest) -> Bool {
        return request.url?.host != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        var mutableRequest = request
        mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return mutableRequest
    }

    override func startLoading() {
        let canonical = Self.canonicalRequest(for: request)
        let task = URLSession.shared.dataTask(with: canonical) { [weak self] data, response, error in
            if let error {
                self?.client?.urlProtocol(self!, didFailWithError: error)
                return
            }
            if let response {
                self?.client?.urlProtocol(self!, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data {
                self?.client?.urlProtocol(self!, didLoad: data)
            }
            self?.client?.urlProtocolDidFinishLoading(self!)
        }
        task.resume()
    }

    override func stopLoading() {}
}

class SbClient {
    private let baseURL: String
    private let token: String
    private let session: URLSession

    init(baseURL: String, token: String) {
        let trimmed = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.baseURL = trimmed
        self.token = token
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.protocolClasses = [AuthURLProtocol.self]
        AuthURLProtocol.token = token
        self.session = URLSession(configuration: config)
    }

    private func makeURL(_ path: String) -> String {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        if trimmed.isEmpty {
            return baseURL
        }
        return "\(baseURL)/\(trimmed)"
    }

    private func makeRequest(url: String, method: String = "GET", body: String? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        if let body {
            request.httpBody = body.data(using: .utf8)
            request.setValue("text/markdown", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    func testConnection() async throws -> String {
        let url = makeURL("/")
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SbError.network("Invalid response")
        }

        if httpResponse.statusCode == 401 {
            throw SbError.authFailed
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw SbError.serverError("Status: \(httpResponse.statusCode) - \(body.prefix(200))")
        }
        return "Connection successful"
    }

    func saveNote(content: String) async throws -> SaveResult {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        let year = formatter.string(from: now)
        formatter.dateFormat = "MM"
        let month = formatter.string(from: now)

        let filename = extractHeading(from: content) ?? timestampFilename(from: now)
        let path = "Inbox/\(year)/\(month)/\(filename).md"
        return try await saveNoteToPath(path: path, content: content)
    }

    func fetchNote(path: String) async throws -> String {
        let url = makeURL(path)
        let request = makeRequest(url: url)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SbError.network("Invalid response")
        }

        if httpResponse.statusCode == 404 {
            return ""
        }
        if httpResponse.statusCode == 401 {
            throw SbError.authFailed
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SbError.serverError("Status: \(httpResponse.statusCode)")
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    func saveNoteToPath(path: String, content: String) async throws -> SaveResult {
        let url = makeURL(path)
        let request = makeRequest(url: url, method: "PUT", body: content)
        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SbError.network("Invalid response")
        }
        if httpResponse.statusCode == 401 {
            throw SbError.authFailed
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SbError.serverError("Status: \(httpResponse.statusCode)")
        }
        return SaveResult(path: path, url: url)
    }

    private func extractHeading(from content: String) -> String? {
        guard let firstLine = content.split(separator: "\n", omittingEmptySubsequences: true).first,
              firstLine.hasPrefix("# "),
              let range = firstLine.range(of: "# ") else {
            return nil
        }
        let text = String(firstLine[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        let sanitized = sanitizeFilename(text)
        return sanitized.isEmpty ? nil : sanitized
    }

    private func sanitizeFilename(_ text: String) -> String {
        let result = text.map { c in
            c.isLetter || c.isNumber || c == "-" || c == "_" || c == " " ? c : "-"
        }
        var str = String(result)
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "-")
            .lowercased()
        while str.contains("--") {
            str = str.replacingOccurrences(of: "--", with: "-")
        }
        return str.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func timestampFilename(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let base = formatter.string(from: date)
        let ms = Int(date.timeIntervalSince1970 * 1000) % 1000
        return "\(base)-\(String(format: "%03d", ms))"
    }
}