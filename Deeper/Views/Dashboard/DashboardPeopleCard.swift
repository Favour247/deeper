//
//  DashboardPeopleCard.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import SwiftUI

struct DashboardPeopleCard: View {
    let title: String
    let icon: String
    let color: Color
    let people: [MergedPerson]
    let isLoading: Bool
    var showSentReceived: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)

            if people.isEmpty && !isLoading {
                Text("No data yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(people.enumerated()), id: \.element.id) { index, person in
                    HStack(spacing: 10) {
                        Text("#\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        Circle()
                            .fill(person.platforms.first?.color ?? .gray)
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text(String(person.displayName.prefix(1)).uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(person.displayName)
                                .font(.callout)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            if showSentReceived {
                                HStack(spacing: 8) {
                                    Label("\(person.messagesSent)", systemImage: "arrow.up")
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                    Label("\(person.messagesReceived)", systemImage: "arrow.down")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                }
                            }
                        }

                        Spacer()

                        HStack(spacing: 2) {
                            ForEach(person.platforms) { platform in
                                Image(systemName: platform.iconName)
                                    .font(.system(size: 9))
                                    .foregroundStyle(platform.color)
                            }
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
