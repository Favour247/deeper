//
//  PlatformsView.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import SwiftUI
import Charts

struct PlatformsView: View {
    var store: DataStore
    @State private var selectedPlatform: PlatformStats?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if store.isLoading && !store.isCached {
                    ProgressView("Loading platforms...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.vertical, 100)
                } else if store.platformStats.isEmpty {
                    ContentUnavailableView(
                        "No Platforms",
                        systemImage: "app.dashed",
                        description: Text("Connect accounts in Beeper to see platform stats")
                    )
                } else {
                    // MARK: - Donut Chart
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Chat Distribution")
                                .font(.headline)
                            Chart(store.platformStats) { stat in
                                SectorMark(
                                    angle: .value("Chats", stat.chatCount),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .foregroundStyle(stat.platform.color)
                                .cornerRadius(4)
                            }
                            .frame(height: 220)

                            // Legend
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(store.platformStats) { stat in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(stat.platform.color)
                                            .frame(width: 8, height: 8)
                                        Text(stat.platform.displayName)
                                            .font(.caption)
                                        Spacer()
                                        Text("\(stat.chatCount)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))

                        // MARK: - Groups vs DMs
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Groups vs DMs")
                                .font(.headline)
                            Chart(store.platformStats) { stat in
                                BarMark(
                                    x: .value("Platform", stat.platform.displayName),
                                    y: .value("Count", stat.dmCount)
                                )
                                .foregroundStyle(.blue)
                                .position(by: .value("Type", "DMs"))

                                BarMark(
                                    x: .value("Platform", stat.platform.displayName),
                                    y: .value("Count", stat.groupCount)
                                )
                                .foregroundStyle(.orange)
                                .position(by: .value("Type", "Groups"))
                            }
                            .chartForegroundStyleScale([
                                "DMs": .blue,
                                "Groups": .orange
                            ])
                            .frame(height: 220)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    }

                    // MARK: - Platform Cards
                    Text("Platform Details")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(store.platformStats) { stat in
                            PlatformCard(stat: stat)
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Platforms")
    }
}

struct PlatformCard: View {
    let stat: PlatformStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: stat.platform.iconName)
                    .font(.title2)
                    .foregroundStyle(stat.platform.color)
                Text(stat.platform.displayName)
                    .font(.headline)
                Spacer()
            }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                StatMini(label: "Chats", value: "\(stat.chatCount)")
                StatMini(label: "Unread", value: "\(stat.unreadCount)")
                StatMini(label: "DMs", value: "\(stat.dmCount)")
                StatMini(label: "Groups", value: "\(stat.groupCount)")
            }

            if !stat.topContacts.isEmpty {
                Divider()
                Text("Top Contacts")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(Array(stat.topContacts.prefix(5))) { person in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(stat.platform.color.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay {
                                Text(String(person.displayName.prefix(1)).uppercased())
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(stat.platform.color)
                            }
                        Text(person.displayName)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

struct StatMini: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
