import SwiftUI

struct InstructionsView: View {
    @EnvironmentObject var appState: AppState
    @State private var alertMessage: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                
                VStack(alignment: .leading, spacing: 12) {
                    Text("1) Allow GoBigBed to access your Sleep data in Apple Health.")
                        .font(.title3.bold())
                        .foregroundColor(Theme.text)

                    Button(action: requestHealthAccess) {
                        Text(appState.healthManager.hasSleepAccess
                             ? "Health Access Enabled"
                             : "Allow Health Access")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(appState.healthManager.hasSleepAccess)

                    Text("You can change this anytime in the Health app\n→ **Browse › Sleep › Data Sources & Access.**")
                        .font(.subheadline)
                        .foregroundColor(Theme.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

               
                VStack(alignment: .leading, spacing: 12) {
                    Text("2) How to Track Sleep")
                        .font(.title3.bold())
                        .foregroundColor(Theme.text)

                    Text("Before going to bed, press the **Start Your Sleep Session** button in **Sleep Tracking** to begin tracking your sleep. **Do Not Move Your Phone after starting a sleep session**, the timer will stop. When you end the session, it will be written into your **Apple Health** sleep data.")
                        .foregroundColor(Theme.text)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                
                VStack(alignment: .leading, spacing: 12) {
                    Text("3) Rewards")
                        .font(.title3.bold())
                        .foregroundColor(Theme.text)

                    Text("Get **points** for every hour you sleep; reach **point milestones** to earn **credits**; exchange credits for **rewards at school**.")
                        .foregroundColor(Theme.text)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                
                VStack(alignment: .leading, spacing: 12) {
                    Text("4) Motivation")
                        .font(.title3.bold())
                        .foregroundColor(Theme.text)

                    Text("Need motivation? Check out the **Motivation** tab to learn how your sleep is connected to our cute lion and to view **statistics and lessons** that encourage great sleep.")
                        .foregroundColor(Theme.text)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
            }
            .padding()
        }
        .tint(Theme.red)
        .background(Theme.black.ignoresSafeArea())
        .onAppear {
           
            appState.healthManager.refreshAuthorizationStatus()
        }
        .alert("Health Access", isPresented: Binding(get: {
            !alertMessage.isEmpty
        }, set: { _ in
            alertMessage = ""
        })) {
            Button("OK", role: .cancel) { alertMessage = "" }
        } message: {
            Text(alertMessage)
        }
    }

    
    private func requestHealthAccess() {
        appState.healthManager.requestAuthorization { granted in
            alertMessage = granted
            ? "Thanks! Health access is enabled."
            : "We couldn’t enable Health access. You can try again or enable it in the Health app (Browse › Sleep › Data Sources & Access)."
        }
    }
}
