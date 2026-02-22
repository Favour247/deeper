//
//  ResponseTimeView.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 23.02.2026.
//

import SwiftUI
import Charts

struct ResponseTimeView: View {
    var store: DataStore
    @State private var sortBy: SortOption = .myFastest
    @State private var dateRange: AnalyticsDateRange = .all

    enum SortOption: String, CaseIterable {
        case myFastest = "My Fastest"
        case mySlowest = "My Slowest"
        case theirFastest = "Their Fastest"
        case theirSlowest = "Their Slowest"
    }

    private var stats: ResponseTimeStats {
        store.responseTimeStats(for: dateRange)
    }

    var sortedPeople: [PersonResponseTime] {
        let filtered = stats.perPerson.filter { $0.myResponseCount > 0 || $0.theirResponseCount > 0 }
        switch sortBy {
        case .myFastest:
            return filtered.filter { $0.myResponseCount > 0 }.sorted { $0.myAvgResponseSec < $1.myAvgResponseSec }
        case .mySlowest:
            return filtered.filter { $0.myResponseCount > 0 }.sorted { $0.myAvgResponseSec > $1.myAvgResponseSec }
        case .theirFastest:
            return filtered.filter { $0.theirResponseCount > 0 }.sorted { $0.theirAvgResponseSec < $1.theirAvgResponseSec }
        case .theirSlowest:
            return filtered.filter { $0.theirResponseCount > 0 }.sorted { $0.theirAvgResponseSec > $1.theirAvgResponseSec }
        }
    }

    var body: some View {
        ScrollView {
            if store.isLoading && store.responseTimeStats.perPerson.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                    Text(store.loadingProgress ?? "Loading…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            } else if store.responseTimeStats.perPerson.isEmpty {
                ContentUnavailableView(
                    "No Response Time Data",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Sync your data to see response time analytics")
                )
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Summary Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        StatCard(title: "My Avg Reply", value: stats.myAvgFormatted, icon: "arrow.turn.up.right", color: .blue)
                        StatCard(title: "Their Avg Reply", value: stats.theirAvgFormatted, icon: "arrow.turn.down.left", color: .green)
                        StatCard(title: "My Replies", value: "\(stats.totalMyResponses)", icon: "paperplane.fill", color: .purple)
                        StatCard(title: "Their Replies", value: "\(stats.totalTheirResponses)", icon: "tray.fill", color: .orange)
                    }

                    // MARK: - Charts
                    HStack(alignment: .top, spacing: 16) {
                        // Top 10 fastest I reply to
                        VStack(alignment: .leading, spacing: 12) {
                            Text("I Reply Fastest To")
                                .font(.headline)

                            let fastest = Array(stats.perPerson
                                .filter { $0.myResponseCount > 0 }
                                .sorted { $0.myAvgResponseSec < $1.myAvgResponseSec }
                                .prefix(10))

                            if fastest.isEmpty {
                                Text("Not enough data")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 40)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Chart(fastest) { person in
                                    BarMark(
                                        x: .value("Time", person.myAvgResponseSec / 60),
                                        y: .value("Person", person.personName)
                                    )
                                    .foregroundStyle(person.platform.color.gradient)
                                    .cornerRadius(4)
                                    .annotation(position: .trailing, alignment: .leading) {
                                        Text(person.myAvgFormatted)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks { value in
                                        AxisValueLabel {
                                            if let mins = value.as(Double.self) {
                                                Text("\(Int(mins))m")
                                            }
                                        }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { _ in AxisValueLabel() }
                                }
                                .frame(height: max(CGFloat(fastest.count * 28), 100))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))

                        // Top 10 fastest they reply
                        VStack(alignment: .leading, spacing: 12) {
                            Text("They Reply Fastest")
                                .font(.headline)

                            let fastest = Array(stats.perPerson
                                .filter { $0.theirResponseCount > 0 }
                                .sorted { $0.theirAvgResponseSec < $1.theirAvgResponseSec }
                                .prefix(10))

                            if fastest.isEmpty {
                                Text("Not enough data")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 40)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Chart(fastest) { person in
                                    BarMark(
                                        x: .value("Time", person.theirAvgResponseSec / 60),
                                        y: .value("Person", person.personName)
                                    )
                                    .foregroundStyle(person.platform.color.gradient)
                                    .cornerRadius(4)
                                    .annotation(position: .trailing, alignment: .leading) {
                                        Text(person.theirAvgFormatted)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks { value in
                                        AxisValueLabel {
                                            if let mins = value.as(Double.self) {
                                                Text("\(Int(mins))m")
                                            }
                                        }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { _ in AxisValueLabel() }
                                }
                                .frame(height: max(CGFloat(fastest.count * 28), 100))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .glassEffect(.regular, in: .rect(cornerRadius: 16))
                    }

                    // MARK: - Full Leaderboard
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Response Time Leaderboard")
                                .font(.headline)
                            Spacer()
                            Picker("Sort", selection: $sortBy) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 400)
                        }

                        ForEach(Array(sortedPeople.prefix(30).enumerated()), id: \.element.id) { index, person in
                            HStack(spacing: 12) {
                                Text("#\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 28)

                                ZStack {
                                    Circle()
                                        .fill(person.platform.color.gradient)
                                        .frame(width: 36, height: 36)
                                    Text(String(person.personName.prefix(1)).uppercased())
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(person.personName)
                                        .font(.callout)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    HStack(spacing: 2) {
                                        Image(systemName: person.platform.iconName)
                                            .font(.system(size: 9))
                                        Text(person.platform.displayName)
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(person.platform.color)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    HStack(spacing: 8) {
                                        VStack(alignment: .trailing, spacing: 1) {
                                            Text("My reply")
                                                .font(.system(size: 8))
                                                .foregroundStyle(.tertiary)
                                            Text(person.myResponseCount > 0 ? person.myAvgFormatted : "—")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.blue)
                                        }
                                        VStack(alignment: .trailing, spacing: 1) {
                                            Text("Their reply")
                                                .font(.system(size: 8))
                                                .foregroundStyle(.tertiary)
                                            Text(person.theirResponseCount > 0 ? person.theirAvgFormatted : "—")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                            .background(
                                index < 3 ? person.platform.color.opacity(0.06) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .glassEffect(.regular, in: .rect(cornerRadius: 16))
                }
                .padding(24)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("Range", selection: $dateRange) {
                    ForEach(AnalyticsDateRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
        }
        .navigationTitle("Response Time")
    }
}
