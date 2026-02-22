//
//  PersonDetailView.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import SwiftUI
import Charts

struct PersonDetailView: View {
    let person: MergedPerson

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(person.platforms.first?.color.gradient ?? Color.gray.gradient)
                            .frame(width: 64, height: 64)
                        Text(String(person.displayName.prefix(1)).uppercased())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(person.displayName)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("\(person.platformCount) platform\(person.platformCount == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if person.totalMessageCount > 0 {
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("\(person.totalMessageCount)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                            Text("messages")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 10) {
                                Label("\(person.messagesSent)", systemImage: "arrow.up")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Label("\(person.messagesReceived)", systemImage: "arrow.down")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .glassEffect(.regular, in: .rect(cornerRadius: 16))

                // MARK: - Connection Type
                HStack(spacing: 12) {
                    Image(systemName: person.connectionType.icon)
                        .font(.title2)
                        .foregroundStyle(connectionColor(for: person.connectionType))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(person.connectionType.label)
                            .font(.headline)
                            .foregroundStyle(connectionColor(for: person.connectionType))
                        Text(connectionDescription(for: person))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if person.totalMessageCount > 0 {
                        Text("\(Int(person.reciprocityScore * 100))%")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(connectionColor(for: person.connectionType))
                        Text("reciprocity")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .glassEffect(.regular, in: .rect(cornerRadius: 16))

                // MARK: - Platform Breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Platform Breakdown")
                        .font(.headline)

                    if person.presences.count > 1 {
                        Chart(person.presences) { presence in
                            SectorMark(
                                angle: .value("Messages", max(presence.messageCount, 1)),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(presence.platform.color)
                            .cornerRadius(4)
                        }
                        .frame(height: 180)
                    }

                    ForEach(person.presences) { presence in
                        HStack(spacing: 12) {
                            Image(systemName: presence.platform.iconName)
                                .font(.title3)
                                .foregroundStyle(presence.platform.color)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(presence.platform.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("\(presence.chatIDs.count) chat\(presence.chatIDs.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if presence.messageCount > 0 {
                                HStack(spacing: 8) {
                                    Label("\(presence.messagesSent)", systemImage: "arrow.up")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                    Label("\(presence.messagesReceived)", systemImage: "arrow.down")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }

                            if let date = presence.lastActivity {
                                Text(date, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .glassEffect(.regular, in: .rect(cornerRadius: 16))
            }
            .padding(24)
        }
    }

    func connectionColor(for type: ConnectionType) -> Color {
        switch type {
        case .twoWay: .green
        case .theyGhost: .orange
        case .iGhost: .purple
        case .inactive: .gray
        }
    }

    func connectionDescription(for person: MergedPerson) -> String {
        switch person.connectionType {
        case .twoWay:
            "You both actively message each other"
        case .theyGhost:
            "You sent \(person.messagesSent) but only got \(person.messagesReceived) back"
        case .iGhost:
            "They sent \(person.messagesReceived) but you only sent \(person.messagesSent)"
        case .inactive:
            "No recent message activity"
        }
    }
}
