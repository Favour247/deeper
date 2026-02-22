//
//  GroupsView.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 22.02.2026.
//

import SwiftUI
import Charts

struct GroupsView: View {
    var store: DataStore
    @State private var selectedPlatform: PlatformGroupStats?
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if store.isLoading && !store.isCached {
                    ProgressView("Loading groups...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 100)
                } else if store.groupStats.isEmpty {
                    ContentUnavailableView(
                        "No Groups",
                        systemImage: "person.3.fill",
                        description: Text("No group chats found")
                    )
                } else {
                    // MARK: - Summary Cards
                    let totalGroups = store.groupStats.reduce(0) { $0 + $1.totalGroups }
                    let totalMembers = store.groupStats.reduce(0) { $0 + $1.totalMembers }
                    let totalUnread = store.groupStats.reduce(0) { $0 + $1.totalUnread }
                    let totalMuted = store.groupStats.reduce(0) { $0 + $1.mutedCount }

                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        StatCard(title: "Groups", value: "\(totalGroups)", icon: "person.3.fill", color: .blue)
                        StatCard(title: "Members", value: "\(totalMembers)", icon: "person.2.fill", color: .green)
                        StatCard(title: "Unread", value: "\(totalUnread)", icon: "envelope.badge.fill", color: .orange)
                        StatCard(title: "Muted", value: "\(totalMuted)", icon: "bell.slash.fill", color: .gray)
                    }

                    // MARK: - Groups per Platform Chart
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Groups by Platform")
                                .font(.headline)

                            Chart(store.groupStats) { stat in
                                SectorMark(
                                    angle: .value("Groups", stat.totalGroups),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2
                                )
                                .foregroundStyle(stat.platform.color)
                                .cornerRadius(4)
                            }
                            .frame(height: 200)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(store.groupStats) { stat in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(stat.platform.color)
                                            .frame(width: 8, height: 8)
                                        Text(stat.platform.displayName)
                                            .font(.caption)
                                        Spacer()
                                        Text("\(stat.totalGroups)")
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

                        // MARK: - Largest Groups
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Largest Groups")
                                .font(.headline)

                            let allGroups = store.groupStats.flatMap(\.groups)
                                .sorted { $0.memberCount > $1.memberCount }
                            let topGroups = Array(allGroups.prefix(10))

                            Chart(topGroups) { group in
                                BarMark(
                                    x: .value("Members", group.memberCount),
                                    y: .value("Group", group.title)
                                )
                                .foregroundStyle(group.platform.color)
                                .cornerRadius(4)
                                .annotation(position: .trailing, alignment: .leading) {
                                    Text("\(group.memberCount)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .chartYAxis {
                                AxisMarks { _ in
                                    AxisValueLabel()
                                }
                            }
                            .frame(height: max(CGFloat(topGroups.count * 28), 100))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    }

                    // MARK: - Per-Platform Group Lists
                    ForEach(store.groupStats) { platformStat in
                        PlatformGroupCard(stat: platformStat, searchText: searchText)
                    }
                }
            }
            .padding(24)
        }
        .searchable(text: $searchText, prompt: "Search groups")
        .navigationTitle("Groups")
    }
}

struct PlatformGroupCard: View {
    let stat: PlatformGroupStats
    let searchText: String
    @State private var isExpanded = true
    @State private var showAll = false

    var filteredGroups: [GroupInfo] {
        if searchText.isEmpty { return stat.groups }
        return stat.groups.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: stat.platform.iconName)
                        .font(.title3)
                        .foregroundStyle(stat.platform.color)
                        .frame(width: 28)

                    Text(stat.platform.displayName)
                        .font(.headline)

                    Spacer()

                    HStack(spacing: 12) {
                        MiniStat(icon: "person.3.fill", value: "\(stat.totalGroups)", color: stat.platform.color)
                        MiniStat(icon: "person.2.fill", value: "\(stat.totalMembers)", color: .secondary)
                        if stat.totalUnread > 0 {
                            MiniStat(icon: "envelope.badge.fill", value: "\(stat.totalUnread)", color: .orange)
                        }
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                let displayGroups = showAll ? filteredGroups : Array(filteredGroups.prefix(8))

                if filteredGroups.isEmpty {
                    Text("No groups match search")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ForEach(displayGroups) { group in
                        GroupRow(group: group)
                    }

                    if filteredGroups.count > 8 {
                        Button {
                            withAnimation { showAll.toggle() }
                        } label: {
                            Text(showAll ? "Show Less" : "Show All \(filteredGroups.count) Groups")
                                .font(.caption)
                                .foregroundStyle(stat.platform.color)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

struct GroupRow: View {
    let group: GroupInfo

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(group.platform.color.gradient)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(String(group.title.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(group.title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label("\(group.memberCount)", systemImage: "person.2.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if group.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.yellow)
                    }
                    if group.isMuted {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.gray)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if group.unreadCount > 0 {
                    Text("\(group.unreadCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(group.platform.color, in: Capsule())
                }

                if let date = group.lastActivity {
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

struct MiniStat: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(color)
    }
}
