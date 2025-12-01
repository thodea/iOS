//
//  Extensions.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/27/24.
//

import Foundation
import UIKit
import FirebaseFirestore
import UniformTypeIdentifiers
import PhotosUI
import _PhotosUI_SwiftUI

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}


/// Formats a number into a string with k, m, b, or t suffix.
func formatNumber(_ num: Int) -> String {
    if num >= 1_000_000_000_000 {
        return String(format: "%.1ft", Double(num) / 1_000_000_000_000).replacingOccurrences(of: ".0", with: "")
    }
    if num >= 1_000_000_000 {
        return String(format: "%.1fb", Double(num) / 1_000_000_000).replacingOccurrences(of: ".0", with: "")
    }
    if num >= 1_000_000 {
        return String(format: "%.1fm", Double(num) / 1_000_000).replacingOccurrences(of: ".0", with: "")
    }
    if num >= 1_000 {
        return String(format: "%.1fk", Double(num) / 1_000).replacingOccurrences(of: ".0", with: "")
    }
    return "\(num)"
}

extension String {
    func toMarkdown() -> AttributedString {
        var attributedString = AttributedString(self)
        
        // 1. Create a Data Detector for links
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return attributedString
        }
        
        // 2. Find matches in the string
        let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        
        // 3. Iterate matches and apply the .link attribute
        for match in matches.reversed() { // Reverse to avoid index shifting issues
            guard let range = Range(match.range, in: self) else { continue }
            guard let url = match.url else { continue }
            
            // Convert String range to AttributedString range
            if let attributedRange = attributedString.range(of: self[range]) {
                attributedString[attributedRange].link = url
                // Optional: Underline to look like a link
            }
        }
        
        return attributedString
    }
}



struct SignedPostResponse: Codable {
    let url: String
    let fields: [String: String]
}

enum UploadError: Error {
    case fileTooLarge
    case backendError(String)
    case uploadFailed
    case invalidResponse
}

final class UploadService {
    // Maximum file size (7 MB)
    let maxSizeInBytes: Int = 7 * 1024 * 1024

    // The server endpoint that returns signed post (same as your Next.js POST)
    let signedPostEndpoint: URL

    init(signedPostEndpoint: URL) {
        self.signedPostEndpoint = signedPostEndpoint
    }

    // Public function: returns true if upload succeeded
    func uploadImageData(_ data: Data, originalFilename: String, username: String) async throws -> Bool {
        // 1. size check
        guard data.count <= maxSizeInBytes else {
            throw UploadError.fileTooLarge
        }

        // 2. build unique filename similar to JS (timestamp + extension)
        let ext = (originalFilename as NSString).pathExtension.lowercased()
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        // Example: user/<username>/asset<timestamp>.<ext>
        let remoteFilename = "user/\(username)/asset\(timestamp).\(ext)"

        // 3. ask backend for signed post fields
        let signed = try await requestSignedPost(for: remoteFilename, username: username)

        // 4. build multipart/form-data body including signed fields + file
        let uploadSuccess = try await uploadToSignedURL(signed: signed, fileData: data, fileFieldName: "file", fileName: (remoteFilename as NSString).lastPathComponent, mimeType: mimeType(for: ext))

        return uploadSuccess
    }

    // MARK: - Private helpers

    private func requestSignedPost(for filename: String, username: String) async throws -> SignedPostResponse {
        var req = URLRequest(url: signedPostEndpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let bodyObj: [String: Any] = ["query": ["file": filename, "username": username]]
        req.httpBody = try JSONSerialization.data(withJSONObject: bodyObj, options: [])

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? "no body"
            throw UploadError.backendError("Signed post endpoint returned error: \(text)")
        }

        // The Next.js response returns fields like { url, fields } which can be decoded
        let decoder = JSONDecoder()
        // Some backends wrap response differently — adapt if needed
        let decoded = try decoder.decode(SignedPostResponse.self, from: data)
        return decoded
    }

    private func uploadToSignedURL(signed: SignedPostResponse, fileData: Data, fileFieldName: String, fileName: String, mimeType: String) async throws -> Bool {
        // prepare URLRequest
        guard let url = URL(string: signed.url) else {
            throw UploadError.invalidResponse
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let body = try buildMultipartBody(fields: signed.fields, fileFieldName: fileFieldName, fileName: fileName, fileData: fileData, mimeType: mimeType, boundary: boundary)

        // Optionally set timeout
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.upload(for: request, from: body)

        guard let http = response as? HTTPURLResponse else {
            throw UploadError.uploadFailed
        }

        // GCS responds with 204 or 201 or 201? The browser typically gets 204/201. We'll treat 2xx as success:
        if (200..<300).contains(http.statusCode) {
            return true
        } else {
            // If upload fails, you might get html error text back
            let text = String(data: data, encoding: .utf8) ?? "no body"
            throw UploadError.backendError("GCS upload failed: status \(http.statusCode) body: \(text)")
        }
    }

    private func buildMultipartBody(fields: [String: String], fileFieldName: String, fileName: String, fileData: Data, mimeType: String, boundary: String) throws -> Data {
        var body = Data()

        func append(_ string: String) {
            if let d = string.data(using: .utf8) {
                body.append(d)
            }
        }

        // Fields (the order matters sometimes; match how browser FormData would append — typically fields then file)
        for (key, value) in fields {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            append("\(value)\r\n")
        }

        // File part
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileName)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        append("\r\n")

        append("--\(boundary)--\r\n")
        return body
    }

    private func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
            case "jpg", "jpeg": return "image/jpeg"
            case "png": return "image/png"
            case "gif": return "image/gif"
            case "heic": return "image/heic"
            default: return "application/octet-stream"
        }
    }
}

func updateProfileUrlInFirestore(username: String, url: String) async throws {
    let db = Firestore.firestore()
    try await db.collection("user").document(username).updateData(["profileUrl": url])
}

extension PhotosPickerItem {
    func fileExtension() async -> String? {
        guard let identifier = self.supportedContentTypes.first?.identifier else { return nil }
        if let ext = UTType(identifier)?.preferredFilenameExtension {
            return ext.lowercased()
        }
        return nil
    }
}

