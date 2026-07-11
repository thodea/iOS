//
//  AppConfig.swift
//  thodea
//
//  Created by Nikolay Pevnev on 7/6/26.
//

import Foundation

enum AppConfig {
    static let streamPullZone: String = {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let zone = plist["BUNNY_STREAM_PULL_ZONE"] as? String else {
            print("⚠️ [Config Error] BUNNY_STREAM_PULL_ZONE not found in Plist.")
            return ""
        }
        return zone
    }()
}
