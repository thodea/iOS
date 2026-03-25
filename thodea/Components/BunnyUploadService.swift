//
//  Untitled.swift
//  thodea
//
//  Created by Nikolay Pevnev on 3/23/26.
//

import Foundation
import SwiftUI
// 1. Change to ObservableObject

class BunnyUploadService: NSObject, ObservableObject, URLSessionTaskDelegate {
    
    // 2. Use @Published so the UI listens to these changes
    @Published var progress: Double = 0.0
    @Published var isUploading: Bool = false
    
    private let signingEndpoint = "https://www.thodea.com/api/upload/sign"

    func uploadImage(data: Data, username: String, fileExtension: String) async throws -> String? {
        // 1. Construct the path here (Logic moved from View to Service)
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let generatedPath = "user/\(username)/asset\(timestamp).\(fileExtension)"

        await MainActor.run {
            self.isUploading = true
            self.progress = 0.0
        }

        // 2. Get Signing Info using the generated path
        guard let signURL = URL(string: signingEndpoint) else { return nil }
        var signRequest = URLRequest(url: signURL)
        signRequest.httpMethod = "POST"
        signRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        signRequest.httpBody = try? JSONSerialization.data(withJSONObject: ["path": generatedPath])

        let (authData, _) = try await URLSession.shared.data(for: signRequest)
        let authResponse = try JSONDecoder().decode(BunnyAuthResponse.self, from: authData)

        // 3. Upload to Bunny
        let finalUrl = try await uploadToBunny(
            data: data,
            uploadUrl: authResponse.uploadUrl,
            accessKey: authResponse.accessKey,
            cdnUrl: authResponse.cdnUrl
        )
        
        await MainActor.run { self.isUploading = false }
        return finalUrl
    }

    private func uploadToBunny(data: Data, uploadUrl: String, accessKey: String, cdnUrl: String) async throws -> String? {
        guard let url = URL(string: uploadUrl) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(accessKey, forHTTPHeaderField: "AccessKey")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        // Use 'self' as delegate to catch the urlSession(_:task:didSendBodyData:) calls
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.uploadTask(with: request, from: data) { _, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                    continuation.resume(returning: cdnUrl)
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            }
            task.resume()
        }
    }

    // Progress Tracking
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let calculatedProgress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        
        // Ensure UI updates happen on the Main Thread
        DispatchQueue.main.async {
            self.progress = calculatedProgress
        }
    }
}


struct BunnyAuthResponse: Codable {
    let uploadUrl: String
    let accessKey: String
    let cdnUrl: String
}
