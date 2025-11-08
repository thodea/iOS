//
//  FullScreenModalView.swift
//  thodea
//
//  Created by Nikolay Pevnev on 1/22/25.
//


import SwiftUI
import SafariServices

struct FullScreenModalView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariViewController = SFSafariViewController(url: url)
        let vibrantBlue = UIColor(
            red: 0/255.0,     // Red component (0-255)
            green: 122/255.0, // Green component
            blue: 255/255.0,  // Blue component
            alpha: 1.0        // Opacity
        )

        // Apply the vibrant color to the controls
        safariViewController.preferredControlTintColor = vibrantBlue
        return safariViewController
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}
