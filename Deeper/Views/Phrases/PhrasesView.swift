//
//  PhrasesView.swift
//  Deeper
//
//  Created by Fatih Kadir Akın on 23.02.2026.
//

import SwiftUI
import Charts

struct PhrasesView: View {
    var store: DataStore
    @State private var dateRange: AnalyticsDateRange = .all

    private var stats: PhraseStats {
        store.phraseStats(for: dateRange)
    }

    var body: some View {
        ScrollView {
            if store.isLoading && store.phraseStats.topWords.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                    Text(store.loadingProgress ?? "Loading…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 100)
            } else if store.phraseStats.topWords.isEmpty {
                ContentUnavailableView(
                    "No Phrase Data",
                    systemImage: "text.quote",
                    description: Text("Sync your data to see phrase analytics")
                )
            } else {
                phraseContent
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
        .navigationTitle("Phrases")
    }

    private var phraseContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            phraseSummaryCards
            chartsRow
            wordCloud
        }
        .padding(24)
    }

    private var phraseSummaryCards: some View {
        let stats = stats
        let vocabPct: String = stats.totalWords > 0
            ? String(format: "%.1f%%", Double(stats.uniqueWords) / Double(stats.totalWords) * 100)
            : "—"
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            StatCard(title: "Total Words", value: "\(stats.totalWords)", icon: "textformat.abc", color: .blue)
            StatCard(title: "Unique Words", value: "\(stats.uniqueWords)", icon: "character.textbox", color: .purple)
            StatCard(title: "Avg Length", value: String(format: "%.0f", stats.averageMessageLength), icon: "ruler", color: .orange)
            StatCard(title: "Vocabulary", value: vocabPct, icon: "book.fill", color: .green)
        }
    }

    private var chartsRow: some View {
        HStack(alignment: .top, spacing: 16) {
            topWordsChart
            topPhrasesChart
        }
    }

    private var topWordsChart: some View {
        let topWords = Array(stats.topWords.prefix(20))
        return VStack(alignment: .leading, spacing: 12) {
            Text("Most Used Words")
                .font(.headline)
            Chart(topWords) { word in
                BarMark(
                    x: .value("Count", word.count),
                    y: .value("Word", word.word)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing, alignment: .leading) {
                    Text("\(word.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in AxisValueLabel() }
            }
            .frame(height: max(CGFloat(topWords.count * 24), 100))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private var topPhrasesChart: some View {
        let topBigrams = Array(stats.topBigrams.prefix(15))
        return VStack(alignment: .leading, spacing: 12) {
            Text("Most Used Phrases")
                .font(.headline)
            if topBigrams.isEmpty {
                Text("Not enough data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart(topBigrams) { phrase in
                    BarMark(
                        x: .value("Count", phrase.count),
                        y: .value("Phrase", phrase.word)
                    )
                    .foregroundStyle(.purple.gradient)
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("\(phrase.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in AxisValueLabel() }
                }
                .frame(height: max(CGFloat(topBigrams.count * 24), 100))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }

    private var wordCloud: some View {
        let maxCount = Double(stats.topWords.first?.count ?? 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("All Top Words")
                .font(.headline)
            FlowLayout(spacing: 6) {
                ForEach(stats.topWords) { word in
                    let ratio = Double(word.count) / maxCount
                    let fontSize = max(10, min(22, 10 + ratio * 12))
                    HStack(spacing: 4) {
                        Text(word.word)
                            .font(.system(size: fontSize, weight: .medium))
                        Text("\(word.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(ratio * 0.15 + 0.05), in: Capsule())
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}
