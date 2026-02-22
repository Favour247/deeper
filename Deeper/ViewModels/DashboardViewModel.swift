//
//  DashboardViewModel.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import Foundation

struct HourlyActivityPoint: Identifiable, Codable {
    let hour: Int
    let platform: Platform
    var count: Int
    var id: String { "\(platform.rawValue)_\(hour)" }

    var hourLabel: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "a" : "p"
        return "\(h)\(suffix)"
    }
}
