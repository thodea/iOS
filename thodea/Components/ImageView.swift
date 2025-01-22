import SwiftUI

struct ImageView: View {
    let imageURL: String
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
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            } else {
                Image(systemName: "photo")
                    .frame(width: 40, height: 40)
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
