import SwiftUI

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var inputName: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Go Big Bed")
                .font(.title)
                .bold()
                .padding(.top, 40)

            if let boundName = authManager.userName {
                Text("This device is set up for:")
                    .foregroundColor(.secondary)
                Text(boundName)
                    .bold()

                Button {
                    authManager.signInLocally(name: boundName)
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)

            } else {
                Text("Enter your name to get started.")
                    .foregroundColor(.secondary)

                TextField("Your name", text: $inputName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 32)
                    .textInputAutocapitalization(.words)

                Button {
                    authManager.signInLocally(name: inputName)
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(inputName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(inputName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 32)

                if let err = authManager.lastError {
                    Text(err).foregroundColor(.red)
                }
            }

            Spacer()
        }
        .padding(.bottom, 24)
    }
}
