//
//  SleepTrackingView.swift
//  GOBIGBEDAPP
//
//  Created by Oluwajoba Okeremi on 10/14/25.
//


import SwiftUI

struct SleepTrackingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var store = SleepSessionStore()
    @Environment(\.scenePhase) private var phase

    // track if a session already started and ended once (to award –20 per extra attempt)
    @State private var endedSessionsThisNight = 0
    @State private var showDNDInfo = false

    var body: some View {
        Group {
            if store.isRunning {
                runningView
            } else {
                readyView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: phase) { newPhase in
            if newPhase != .active && store.isRunning {
                // App left foreground while running → abandon → write near-zero & block
                let s = store.startDate ?? Date()
                let nearZeroEnd = s.addingTimeInterval(1) // HK requires end > start
                writeSleepToHealth(start: s, end: nearZeroEnd)
                store.abandonAndBlockNight()
            }
        }
    }

    // MARK: - Ready screen (Start)
    private var readyView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Sleep Tracking")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(SleepSessionStore.formatClock(Date()))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .card()

                Button {
                    maybeStart()
                } label: {
                    Text("Start Your Sleep Session")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canStartNow)
                .opacity(canStartNow ? 1.0 : 0.5)

                VStack(alignment: .leading, spacing: 8) {
                    Text("• Session can run anytime between 8pm – 10am")
                    Text("• Only 1 session per night. Multiple sessions will be penalized.")
                }
                .font(.subheadline)
                .foregroundColor(Theme.textMuted)
                .card()
            }
            .padding()
        }
        .background(Theme.black.ignoresSafeArea())
        .tint(Theme.red)
    }

    // MARK: - Running screen (Stopwatch)
    private var runningView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Sleep Tracking")
                    .font(.largeTitle.bold())
                    .foregroundColor(Theme.text)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Big clock
                Text(SleepSessionStore.formatClock(Date()))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.red)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Stopwatch
                Text(SleepSessionStore.formatStopwatch(store.elapsed))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.text)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .card()

                Button {
                    endSession()
                } label: {
                    Text("End Session")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                VStack(alignment: .leading, spacing: 8) {
                    Text("• Plug in Phone")
                    Text("• Do not close this app, but you can turn off your phone.")
                }
                .font(.subheadline)
                .foregroundColor(Theme.textMuted)
                .card()
            }
            .padding()
        }
        .background(Theme.black.ignoresSafeArea())
        .tint(Theme.red)
        .onAppear {
            // Show a one-time “turn on Do Not Disturb” info sheet.
            // (iOS does NOT allow apps to enable Focus automatically.)
            if !showedDNDTipThisNight() {
                showDNDInfo = true
                setDNDTipShown()
            }
        }
        .sheet(isPresented: $showDNDInfo) {
            DNDInfoSheet()
        }
    }

    // MARK: - Logic

    private var canStartNow: Bool {
        store.isWithinAllowedWindow && !store.isBlockedTonight && appState.healthManager.hasSleepAccess
    }

    private func maybeStart() {
        guard appState.healthManager.hasSleepAccess else {
            // Kick user to enable Health access (button in Instructions tab already does this)
            return
        }
        guard store.isWithinAllowedWindow else { return }
        guard !store.isBlockedTonight else { return }

        // penalty for repeated sessions same night (–20 each extra)
        if store.sessionsThisNight >= 1 {
            appState.rewardManager?.add(points: -20)
            store.incrementPenaltyCount()
        }
        store.start()
    }

    private func endSession() {
        let result = store.endNow()
        // Cap to 10am
        var seconds = result.seconds
        if seconds < SleepSessionStore.minSeconds {
            // < 30 minutes → don’t write
            store.markNightBlocked() // still block additional starts
            return
        }
        writeSleepToHealth(start: result.start, end: result.effectiveEnd)
        store.markNightBlocked()
        endedSessionsThisNight += 1
    }

    private func writeSleepToHealth(start: Date, end: Date) {
        appState.healthManager.saveSleep(start: start, end: end) { _ in
            // Optionally: recompute rewards based on Health (your existing pipeline handles this)
        }
    }

    // MARK: - DND helper (informational)
    private func showedDNDTipThisNight() -> Bool {
        UserDefaults.standard.bool(forKey: "sleeptrack.dnd.shown.\(store.currentNightId)")
    }
    private func setDNDTipShown() {
        UserDefaults.standard.set(true, forKey: "sleeptrack.dnd.shown.\(store.currentNightId)")
    }
}

/// A tiny sheet explaining DND (Focus).
/// iOS apps cannot programmatically enable Do Not Disturb; we give a one-tap path.
private struct DNDInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Turn On Do Not Disturb")
                    .font(.title.bold())
                Text("For the best results, turn on Do Not Disturb (Focus) while tracking sleep. Apps are not allowed to enable Focus automatically.")
                    .foregroundColor(.secondary)
                Button("Open Focus Settings") {
                    // This may or may not deep-link depending on iOS version; still useful to surface.
                    if let url = URL(string: "App-Prefs:root=FOCUS") {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("Got it") { dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
