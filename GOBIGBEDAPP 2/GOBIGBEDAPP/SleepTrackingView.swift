import SwiftUI
import Combine

struct SleepTrackingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = SleepSessionStore()

    var body: some View {
        NavigationView {
            Group {
                if store.isRunning {
                    runningView
                } else {
                    idleView
                }
            }
        }
        .tint(Theme.red)
        .background(Theme.black.ignoresSafeArea())
        .onAppear {
            // 1. Update Health permission state
            appState.healthManager.refreshAuthorizationStatus()

            // 2. Restore / rescue past session if needed
            store.bootstrap()

            // 3. Whenever the store says "session ended for real",
            //    write to HealthKit using the final (start, effectiveEnd).
            store.onAutoEnded = { start, effectiveEnd in
                appState.healthManager.writeSleep(start: start, end: effectiveEnd) { _ in
                    // You can handle points, etc. here if you want.
                    // NOTE: minSeconds is about points, not Health write.
                    // If you still want to gate points, you can compute:
                    // let dur = effectiveEnd.timeIntervalSince(start)
                    // and award only if dur >= SleepSessionStore.minSeconds.
                }
            }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                store.appDidEnterBackground()
            case .active:
                store.appWillEnterForeground()
            default:
                break
            }
        }
    }

    // MARK: - Idle (not running)
    private var idleView: some View {
        VStack(spacing: 12) {
            CurrentTimeView()
                .padding(.bottom, 8)

            Button(action: maybeStart) {
                Text("Start Your Sleep Session")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!store.isWithinAllowedWindow || appState.healthManager.hasSleepAccess == false)

            Text("**Session can run anytime between 8pm – 12pm**")
                .font(.subheadline)
                .foregroundColor(Theme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("**Do Not Move Your Phone, Timer will Stop!**")
                .font(.subheadline)
                .foregroundColor(Theme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card()
    }

    private func maybeStart() {
        guard appState.healthManager.hasSleepAccess else { return }
        guard store.isWithinAllowedWindow else { return }
        store.start()
    }

    // MARK: - Running (active session)
    private var runningView: some View {
        VStack(spacing: 16) {
            CurrentTimeView()

            VStack(spacing: 6) {
                Text(store.elapsedStringMono)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.text)

                Text("Session timer")
                    .font(.subheadline)
                    .foregroundColor(Theme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)

            Button(action: endSession) {
                Text("End Session")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            VStack(alignment: .leading, spacing: 6) {
                Text("**Plug in Your Phone**")
                Text("**Good Night!**")
            }
            .font(.subheadline)
            .foregroundColor(Theme.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card()
    }

    private func endSession() {
        // Unified end path. This will:
        // - compute final duration using wall-clock (even if phone was off forever)
        // - clamp to noon cutoff rules
        // - stop motion/ticker
        // - call onAutoEnded(start,end) so we write to HealthKit exactly once.
        store.endAndNotify(reason: "manual-stop")
    }
}


// unchanged
private struct CurrentTimeView: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(now, style: .time)
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundColor(Theme.text)
            .frame(maxWidth: .infinity, alignment: .center)
            .onReceive(timer) { now = $0 }
    }
}
