//
//  InsightsEngine.swift
//  Runtime
//
//  Created by ned on 01/08/26.
//

import Foundation
import Observation
import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
@Observable
final class InsightsEngine {

    struct FactsSnapshot {
        let today: Date
        let lastRunDate: Date
        let totalRuns: Int
        let totalDistanceKm: Double
        let totalDuration: Duration
        let longestDistanceRun: (distanceKm: Double, date: Date)
        let longestDurationRun: (duration: Duration, date: Date)
        let fastestAveragePace: (pace: Duration, date: Date)?
        let bestTimesByDistance: [(label: String, distanceKm: Int, duration: Duration, date: Date)]
        let fastestSplitPace: (pace: Duration, date: Date)?
        let runsPerYear: [(year: Int, count: Int)]
        let averageRunsPerWeekOverall: Double
        let averageRunsPerWeekByYear: [(year: Int, average: Double)]
    }

    var isGeneratingInsights: Bool = false
    var insightsText: String? = nil

    private let storage: HealthKitStoring
    private let calendar: Calendar
    private let dateFormatter: DateFormatter
    private let numberFormatter: NumberFormatter

    init(
        storage: HealthKitStoring = HealthKitStorage.shared,
        calendar: Calendar = .current
    ) {
        self.storage = storage
        self.calendar = calendar
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.dateFormatter = dateFormatter
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumFractionDigits = 1
        numberFormatter.locale = Locale(identifier: "en_US_POSIX")
        self.numberFormatter = numberFormatter
    }

    var isModelAvailable: Bool {
#if targetEnvironment(simulator)
        return false
#else
        if let isAvailable = systemModelAvailability() {
            return isAvailable
        }
        return false
#endif
    }

    func loadCachedInsights(for workouts: [RunWorkout]) -> Bool {
        guard isModelAvailable, !workouts.isEmpty else {
            insightsText = nil
            return false
        }
        let signature = Self.signature(for: workouts)
        guard
            storage.getInsightsSignature() == signature,
            let cached = storage.getInsightsText()
        else {
            insightsText = nil
            return false
        }
        insightsText = cached
        return true
    }

    func clearCache() {
        storage.clearInsights()
        insightsText = nil
    }

    func generateInsights(for workouts: [RunWorkout]) async {
        guard !workouts.isEmpty else {
            insightsText = nil
            return
        }
#if targetEnvironment(simulator)
        return
#endif
        guard isModelAvailable else { return }

        let signature = Self.signature(for: workouts)
        let facts = makeFactsSnapshot(from: workouts)
        let prompt = buildPrompt(from: facts)

        isGeneratingInsights = true

        guard let text = await generateText(from: prompt) else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                isGeneratingInsights = false
            }
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            insightsText = text
            isGeneratingInsights = false
        }
        storage.cacheInsights(text: text, signature: signature)
    }

    // MARK: - Prompting

    private func buildPrompt(from facts: FactsSnapshot) -> String {
        var lines: [String] = []
        lines.append("You are a friendly, playful running coach.")
        lines.append("Rules:")
        lines.append("- Use only numbers from the Facts section. Do not invent any numbers.")
        lines.append("- Use \"you\" only. Do not use \"I\", \"we\", or \"has\".")
        lines.append("- Output a bullet list only, containing some compact useful insights. Max 12 bullets.")
        lines.append("- Dates must be formatted as \"MMM d, yyyy\" (e.g. \"Jan 3, 2024\").")
        lines.append("- Include a few relevant emojis.")
        lines.append("- The current year is year-to-date only. Today is \(formatDate(facts.today))")
        lines.append("")
        lines.append("Facts:")
        lines.append("Last run: \(formatDate(facts.lastRunDate))")
        lines.append("Total runs: \(facts.totalRuns)")
        lines.append("Total distance: \(formatDistanceKm(facts.totalDistanceKm)) km")
        lines.append("Total duration: \(formatDurationVerbose(facts.totalDuration))")
        lines.append("Longest run by distance: \(formatDistanceKm(facts.longestDistanceRun.distanceKm)) km on \(formatDate(facts.longestDistanceRun.date))")
        lines.append("Longest run by duration: \(formatDurationClock(facts.longestDurationRun.duration)) on \(formatDate(facts.longestDurationRun.date))")
        if let fastestAveragePace = facts.fastestAveragePace {
            lines.append("Fastest average pace: \(formatPace(fastestAveragePace.pace)) per km on \(formatDate(fastestAveragePace.date))")
        } else {
            lines.append("Fastest average pace: N/A")
        }
        for item in facts.bestTimesByDistance {
            lines.append("Best \(item.label): \(formatDurationClock(item.duration)) on \(formatDate(item.date))")
        }
        if let fastestSplitPace = facts.fastestSplitPace {
            lines.append("Fastest split pace: \(formatPace(fastestSplitPace.pace)) per km on \(formatDate(fastestSplitPace.date))")
        } else {
            lines.append("Fastest split pace: N/A")
        }
        let runsPerYear = facts.runsPerYear
            .map { "\($0.year): \($0.count)" }
            .joined(separator: ", ")
        lines.append("Runs per year: \(runsPerYear)")
        lines.append("Average runs per week (overall): \(formatDecimal(facts.averageRunsPerWeekOverall))")
        let avgPerYear = facts.averageRunsPerWeekByYear
            .map { "\($0.year): \(formatDecimal($0.average))" }
            .joined(separator: ", ")
        lines.append("Average runs per week by year: \(avgPerYear)")
        return lines.joined(separator: "\n")
    }

    private func generateText(from prompt: String) async -> String? {
#if canImport(FoundationModels)
        let session = LanguageModelSession(model: .default)
        do {
            let options = GenerationOptions(
                temperature: 0.75,
                maximumResponseTokens: 300
            )
            let response = try await session.respond(to: prompt, options: options)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            print(error)
            return nil
        }
#endif
        return nil
    }

    private func systemModelAvailability() -> Bool? {
#if canImport(FoundationModels)
        return SystemLanguageModel.default.isAvailable
#endif
        return nil
    }

    // MARK: - Facts

    private func makeFactsSnapshot(from workouts: [RunWorkout]) -> FactsSnapshot {
        let sortedByDate = workouts.sorted { $0.dateInterval.start < $1.dateInterval.start }
        let today = Date()
        let lastRun = workouts.map(\.dateInterval.start).max() ?? today
        let totalRuns = workouts.count

        let totalDistanceMeters = workouts
            .map { $0.totalDistance.converted(to: .meters).value }
            .reduce(0, +)
        let totalDistanceKm = totalDistanceMeters / 1000.0
        let totalDuration = sumDurations(workouts.map(\.totalDuration))

        let longestDistanceWorkout = workouts.max {
            $0.totalDistance.converted(to: .meters).value < $1.totalDistance.converted(to: .meters).value
        } ?? workouts[0]
        let longestDistanceKm = longestDistanceWorkout.totalDistance.converted(to: .kilometers).value

        let longestDurationWorkout = workouts.max {
            $0.totalDuration.inSeconds < $1.totalDuration.inSeconds
        } ?? workouts[0]

        let fastestAveragePace = workouts
            .compactMap { workout -> (Duration, Date)? in
                guard let pace = workout.averagePace else { return nil }
                return (pace, workout.dateInterval.start)
            }
            .min { $0.0.inSeconds < $1.0.inSeconds }
            .map { (pace: $0.0, date: $0.1) }

        let bestTimesByDistance = bestRaceTimes(for: workouts)
        let fastestSplitPace = bestSplitPace(for: workouts)

        let runsPerYear = runsPerYearSnapshot(for: workouts, today: today)
        let averageRunsPerWeekOverall = averageRunsPerWeek(
            start: sortedByDate.first?.dateInterval.start ?? today,
            end: sortedByDate.last?.dateInterval.start ?? today,
            count: totalRuns
        )
        let averageRunsPerWeekByYear = averageRunsPerWeekByYearSnapshot(for: workouts, years: runsPerYear.map(\.year))

        return FactsSnapshot(
            today: today,
            lastRunDate: lastRun,
            totalRuns: totalRuns,
            totalDistanceKm: totalDistanceKm,
            totalDuration: totalDuration,
            longestDistanceRun: (distanceKm: longestDistanceKm, date: longestDistanceWorkout.dateInterval.start),
            longestDurationRun: (duration: longestDurationWorkout.totalDuration, date: longestDurationWorkout.dateInterval.start),
            fastestAveragePace: fastestAveragePace,
            bestTimesByDistance: bestTimesByDistance,
            fastestSplitPace: fastestSplitPace,
            runsPerYear: runsPerYear,
            averageRunsPerWeekOverall: averageRunsPerWeekOverall,
            averageRunsPerWeekByYear: averageRunsPerWeekByYear
        )
    }

    private func bestRaceTimes(for workouts: [RunWorkout]) -> [(label: String, distanceKm: Int, duration: Duration, date: Date)] {
        let races: [(label: String, km: Int)] = [
            ("5K", 5),
            ("10K", 10),
            ("15K", 15),
            ("Half Marathon", 21),
            ("Marathon", 42)
        ]

        var results: [(label: String, distanceKm: Int, duration: Duration, date: Date)] = []

        for race in races {
            var best: (duration: Duration, date: Date)?
            for workout in workouts {
                let fullSplits = workout.splits.filter { $0.distance.converted(to: .meters).value >= 1000 }
                guard fullSplits.count >= race.km else { continue }
                let durationSeconds = fullSplits
                    .prefix(race.km)
                    .map(\.duration.inSeconds)
                    .reduce(0, +)
                let duration = Duration.seconds(Double(durationSeconds))
                if let currentBest = best {
                    if duration.inSeconds < currentBest.duration.inSeconds {
                        best = (duration, workout.dateInterval.start)
                    }
                } else {
                    best = (duration, workout.dateInterval.start)
                }
            }
            if let best {
                results.append((label: race.label, distanceKm: race.km, duration: best.duration, date: best.date))
            }
        }

        return results
    }

    private func bestSplitPace(for workouts: [RunWorkout]) -> (pace: Duration, date: Date)? {
        var best: (pace: Duration, date: Date)?
        for workout in workouts {
            for split in workout.splits {
                let distanceMeters = split.distance.converted(to: .meters).value
                guard distanceMeters > 0 else { continue }
                let secondsPerKm = Double(split.duration.inSeconds) / (distanceMeters / 1000.0)
                let pace = Duration.seconds(secondsPerKm)
                if let currentBest = best {
                    if pace.inSeconds < currentBest.pace.inSeconds {
                        best = (pace, workout.dateInterval.start)
                    }
                } else {
                    best = (pace, workout.dateInterval.start)
                }
            }
        }
        return best
    }

    private func runsPerYearSnapshot(for workouts: [RunWorkout], today: Date) -> [(year: Int, count: Int)] {
        let currentYear = calendar.component(.year, from: today)
        let yearsWithRuns = workouts.map { calendar.component(.year, from: $0.dateInterval.start) }
        let earliestYear = min(yearsWithRuns.min() ?? currentYear, currentYear)
        var counts: [Int: Int] = [:]
        for workout in workouts {
            let year = calendar.component(.year, from: workout.dateInterval.start)
            counts[year, default: 0] += 1
        }
        return stride(from: currentYear, through: earliestYear, by: -1).map { year in
            (year: year, count: counts[year, default: 0])
        }
    }

    private func averageRunsPerWeekByYearSnapshot(for workouts: [RunWorkout], years: [Int]) -> [(year: Int, average: Double)] {
        var results: [(year: Int, average: Double)] = []
        for year in years {
            let runsInYear = workouts.filter { calendar.component(.year, from: $0.dateInterval.start) == year }
            guard !runsInYear.isEmpty else {
                results.append((year: year, average: 0))
                continue
            }
            let dates = runsInYear.map(\.dateInterval.start).sorted()
            let avg = averageRunsPerWeek(start: dates.first ?? Date(), end: dates.last ?? Date(), count: runsInYear.count)
            results.append((year: year, average: avg))
        }
        return results
    }

    private func averageRunsPerWeek(start: Date, end: Date, count: Int) -> Double {
        let spanSeconds = max(0, end.timeIntervalSince(start))
        let weeks = max(1.0, spanSeconds / (7.0 * 24.0 * 3600.0))
        return Double(count) / weeks
    }

    private func sumDurations(_ durations: [Duration]) -> Duration {
        let totalSeconds = durations.map(\.inSeconds).reduce(0, +)
        return Duration.seconds(Double(totalSeconds))
    }

    // MARK: - Formatting

    private func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    private func formatDistanceKm(_ km: Double) -> String {
        numberFormatter.string(from: NSNumber(value: km)) ?? String(format: "%.1f", km)
    }

    private func formatDurationVerbose(_ duration: Duration) -> String {
        let seconds = max(0, duration.inSeconds)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m \(remainingSeconds)s"
        }
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        }
        return "\(remainingSeconds)s"
    }

    private func formatDurationClock(_ duration: Duration) -> String {
        let seconds = max(0, duration.inSeconds)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func formatPace(_ duration: Duration) -> String {
        duration.paceString
    }

    private func formatDecimal(_ value: Double) -> String {
        numberFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    // MARK: - Signature

    static func signature(for workouts: [RunWorkout]) -> String {
        let parts = workouts.map { workout in
            "\(workout.id.uuidString)|\(workout.dateInterval.start.timeIntervalSince1970)"
        }
        return parts.sorted().joined(separator: "||")
    }
}
