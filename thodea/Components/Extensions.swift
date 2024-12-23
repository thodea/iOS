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
