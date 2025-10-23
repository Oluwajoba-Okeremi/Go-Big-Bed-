import SwiftUI

struct MotivationView: View {
    @EnvironmentObject var appState: AppState

    private let texts: [String] = [
        "70% of U.S. teens get less than eight hours of sleep, so you’ll stand out just by resting right. -NIH PubMed Central (2020)",
        "Every extra hour of sleep lowers sadness risk by 38%. -Newport Academy",
        "Going to bed earlier improves your brain’s sharpness. -The Guardian (2025)",
        "More sleep = sharper memory and larger brain volume. -The Guardian (2025)",
        "Only 2 in 10 teens sleep 8–10 hours a night. Be the 20% -National Sleep Foundation",
        "73% of high schoolers miss recommended sleep hours. -Healthline",
        "Better rest = higher grades and stronger focus. -Nationwide Children’s Hospital",
        "Sleep strengthens memory and locks in what you studied. -Baylor College of Medicine",
        "Sleep improves attention and lowers behavior problems. -American Academy of Sleep Medicine",
        "Too little sleep increases risk of depression and mood swings. -NIH PMC",
        "Each lost hour of sleep raises suicide attempt risk by 58%. -Newport Academy",
        "Sleeping well makes you a safer, faster driver. -NIH PubMed Central",
        "Over half of teen drivers have driven drowsy—sleep saves lives. -RWJBarnabas Health",
        "Short sleep links to obesity, hypertension, and diabetes. -American Academy of Sleep Medicine",
        "Sleep repairs your immune system overnight. -Johns Hopkins Medicine",
        "Skipping sleep may mean skipping height gains",
        "Good sleep reduces inflammation and helps recovery. -Baylor College of Medicine",
        "Teens with poor sleep report more anxiety symptoms. -BMC Sleep Journal",
        "Restful sleep boosts mental and physical well-being. -NIH PMC",
        "Sleep helps you handle stress better. -NIH PubMed Central",
        "Teens who sleep more make safer, smarter choices. -National Sleep Foundation",
        "Enough sleep = fewer accidents and better decisions. -National Sleep Foundation",
        "1 in 4 teens struggles with insomnia—fixing sleep matters. -PBS NewsHour",
        "Sleep loss causes inflammation and metabolic issues. -UCLA Adolescent Sleep Center",
        "Well-rested teens are less likely to skip school. -Nationwide Children’s Hospital",
        "Sleep boosts creativity and problem-solving. -NIH PubMed Central",
        "Dreaming helps your brain process emotions. -NIH PubMed Central",
        "Less sleep = weaker self-control and impulse discipline. -NIH PubMed Central",
        "Regular sleep builds brain plasticity and learning power. -NIH PubMed Central",
        "Sleep protects against anxiety and depression. -BMC Sleep Journal",
        "Every night of rest repairs brain and body cells. -Johns Hopkins Medicine",
        "Adjusting bedtime alone can raise your test scores. -University of Cambridge",
        "Even one extra hour of sleep boosts cognitive ability. -The Guardian (2025)",
        "When you sleep more, you’re sharper and quicker. -Cambridge University",
        "Your brain processes and resets during deep sleep. -NIH PubMed Central",
        "Sleep fights your natural teenage circadian delay. -Sleep Foundation",
        "A steady sleep schedule keeps your rhythm balanced. -Baylor College of Medicine",
        "Rested minds stay calmer and happier. -NIH PubMed Central",
        "Sleep gives you the energy to move and exercise. -RWJBarnabas Health",
        "Sleep balances your hormones and metabolism. -NIH PubMed Central",
        "Sleep protects against long-term inflammation. -Baylor College of Medicine",
        "A little effort today is still a step closer than standing still.",
            "Even five minutes of work plants a seed your future self will thank you for.",
            "Progress doesn’t care how small it is—it only cares that it’s real.",
            "Tiny work still builds massive results, one quiet minute at a time.",
            "Half an assignment done beats a perfect plan that never started.",
            "Don’t wait for inspiration. It’s already waiting for you—on the other side of starting.",
            "Every bit of effort compounds; even the smallest action is momentum.",
            "Consistency beats intensity. Small wins are still wins.",
            "Don’t underestimate the power of a few focused minutes—they stack up into success.",
            "If all you can give today is a little, give it anyway. Little adds up to everything.",
            "Five minutes of focus beats five hours of waiting to feel ready.",
            "Discipline begins the moment motivation fades.",
            "If you can do it now, you’re already ahead of everyone waiting for later.",
            "Small progress made today beats perfect plans made tomorrow.",
            "Momentum is built by motion—start small, but start now.",
            "Your future self is watching. Make them proud by working today.",
            "Excuses don’t get you closer to your goals—minutes of effort do.",
            "You’ll never ‘find time’—you make it by choosing to begin.",
            "If you’ve done what you can today, the best thing left to do is rest.",
            "When the day is done, let it be done. Sleep is the smartest next move.",
            "You don’t need to outwork the night—you just need to meet it with rest.",
            "If your brain is tired, it’s not weakness—it’s a signal to recharge.",
            "Sleep isn’t the end of productivity—it’s the foundation of it.",
            "You worked today. That’s enough. Let rest finish what effort started.",
            "Working when you’re drained doesn’t prove discipline—it just empties you faster.",
            "Exhaustion isn’t effort; it’s your body asking for a timeout.",
            "Pushing through when you’re tired doesn’t build results—it breaks focus.",
            "Tired work isn’t productive work. Rest, then come back sharp.",
            "If your brain is running on fumes, you’re not moving forward—you’re spinning in place.",
            "Grinding while exhausted doesn’t make you stronger—it makes tomorrow harder.",
            "Rest isn’t quitting; it’s smart strategy.",
            "When you’re tired, every minute of work takes twice as long—save the time, get the sleep."
        
    ]

    @State private var current: String = "Don’t underestimate the power of a few focused minutes—small motion is still motion."

    
    @State private var lastNight: Double = 0.0

   
    @State private var gifReloadToken = UUID()

    private var didHitGoal: Bool { lastNight >= 8.0 - 0.001 }
    private var lionImageName: String { didHitGoal ? "sleep_lion_zzz" : "restless_lion_sway" }
    private var lionCaption: String {
        didHitGoal ? "He's Rested! Keep it up!"
                   : "Sleep for 8+ hours! For Both of You!"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                Text("“\(current)”")
                    .font(.title2.bold())
                    .foregroundColor(Theme.text)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .card()

                Button(action: { current = texts.randomElement() ?? current }) {
                    Text("Get Motivated").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                VStack(alignment: .leading, spacing: 12) {
                    Text("Based on Last Recorded Night of Sleep")
                        .font(.headline)
                        .foregroundColor(Theme.text)

                    
                    GIFView(name: lionImageName, maxHeight: 180)
                        .id(gifReloadToken)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    Text(lionCaption)
                        .font(.title3.bold())
                        .foregroundColor(Theme.text)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                .card()

                Spacer(minLength: 8)
            }
            .padding()
        }
        .background(Theme.black.ignoresSafeArea())
        .tint(Theme.red)
        .onAppear {
            computeLastNight()
            bumpGIF()
        }
        .onChange(of: lionImageName) { _ in
            
            bumpGIF()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            
            computeLastNight()
            bumpGIF()
        }
    }

    private func bumpGIF() {
        
        gifReloadToken = UUID()
    }

    
    private func computeLastNight() {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(byAdding: .day, value: -6, to: now) ?? now

        appState.healthManager.fetchDailyHours(startDate: start, endDate: now) { days in
            let nonZero = days.filter { $0.1 > 0 }
            self.lastNight = max(0.0, nonZero.last?.1 ?? 0.0)
        }
    }
}
