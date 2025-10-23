import SwiftUI
import Combine

struct SleepTrackingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store = SleepSessionStore()

    var body: some View {
        NavigationView {
            Group {
                if store.isRunning { runningView } else { idleView }
            }
        }
        .tint(Theme.red)
        .background(Theme.black.ignoresSafeArea())
        .onAppear {
            appState.healthManager.refreshAuthorizationStatus()
            store.bootstrap()

            
            store.onAutoEnded = { start, effectiveEnd in
                appState.healthManager.writeSleep(start: start, end: effectiveEnd) { _ in }
            }
            
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background: store.appDidEnterBackground()
            case .active:     store.appWillEnterForeground()
            default:          break
            }
        }
    }

    
    private var idleView: some View {
        VStack(spacing: 12) {
            CurrentTimeView().padding(.bottom, 8)
            Button(action: maybeStart) { Text("Start Your Sleep Session").frame(maxWidth: .infinity) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!store.isWithinAllowedWindow || appState.healthManager.hasSleepAccess == false)
            Text("**Session can run anytime between 8pm – 12pm**")
                .font(.subheadline).foregroundColor(Theme.textMuted).frame(maxWidth: .infinity, alignment: .leading)
            Text("**Do Not Move Your Phone, Timer will Stop!**")
                .font(.subheadline).foregroundColor(Theme.textMuted).frame(maxWidth: .infinity, alignment: .leading)
        }
        .card()
    }

    private func maybeStart() {
        guard appState.healthManager.hasSleepAccess else { return }
        guard store.isWithinAllowedWindow else { return }
        store.start()
    }

    
    private var runningView: some View {
        VStack(spacing: 16) {
            CurrentTimeView()
            VStack(spacing: 6) {
                Text(store.elapsedStringMono)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.text)
                Text("Session timer").font(.subheadline).foregroundColor(Theme.textMuted)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 4)

            Button(action: endSession) { Text("End Session").frame(maxWidth: .infinity) }
                .buttonStyle(PrimaryButtonStyle())

            VStack(alignment: .leading, spacing: 6) {
                Text("**Plug in Your Phone**")
                Text("**Good Night!**")
            }
            .font(.subheadline).foregroundColor(Theme.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card()
    }

    private func endSession() {
        guard let result = store.endNow() else { return }
        if result.seconds < SleepSessionStore.minSeconds { return }
        if result.effectiveEnd > result.start {
            appState.healthManager.writeSleep(start: result.start, end: result.effectiveEnd) { _ in }
        }
    }
}


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
