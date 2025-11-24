//
//  Extensions.swift
//  thodea
//
//  Created by Nikolay Pevnev on 12/27/24.
//

import UIKit
import Foundation

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

