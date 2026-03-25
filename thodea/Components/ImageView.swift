import SwiftUI
import Foundation
import UIKit

struct ImageView: View {
    let imageURL: String
    let size: CGFloat  // Parameter to control size
    @State private var uiImage: UIImage? = nil
    @State private var isLoading = true
    
    private let cache = URLCache.shared  // Use shared URL cache

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)  // Use the size parameter
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)  // Default image with the same size
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = URL(string: imageURL) else { return }

        // Check if image is already cached
        if let cachedResponse = cache.cachedResponse(for: URLRequest(url: url)),
           let cachedImage = UIImage(data: cachedResponse.data) {
            self.uiImage = cachedImage
            self.isLoading = false
            return
        }

        // If not cached, fetch from the network
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.uiImage = image
                    }
                    
                    // Cache the response
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    cache.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
                }
            } catch {
                uiImage = nil
            }
            isLoading = false
        }
    }
}

func uploadToRailway(image: UIImage, username: String) async throws {
    guard let data = image.jpegData(compressionQuality: 0.7) else { return }
    
    let url = URL(string: "https://your-thodea-app.railway.app/api/upload/ios")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // Pass the username in headers or as a query param
    request.setValue(username, forHTTPHeaderField: "X-Username")
    request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")

    let (_, response) = try await URLSession.shared.upload(for: request, from: data)
    
    if (response as? HTTPURLResponse)?.statusCode == 200 {
        print("Done!")
    }
}
