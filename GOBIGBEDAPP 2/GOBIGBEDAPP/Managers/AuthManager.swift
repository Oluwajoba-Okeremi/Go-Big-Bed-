import Foundation
final class AuthManager: ObservableObject {
    private enum Key {
        static let isAuthenticated = "isAuthenticated"
        static let userName        = "userName"
    }

    @Published var isAuthenticated: Bool {
        didSet { UserDefaults.standard.set(isAuthenticated, forKey: Key.isAuthenticated) }
    }
    @Published var userName: String? {
        didSet { UserDefaults.standard.set(userName, forKey: Key.userName) }
    }

    @Published var lastError: String? = nil

    init() {
        self.isAuthenticated = UserDefaults.standard.bool(forKey: Key.isAuthenticated)
        self.userName = UserDefaults.standard.string(forKey: Key.userName)
    }

    func signInLocally(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastError = "Name cannot be empty."
            return
        }
        DispatchQueue.main.async {
            if self.userName == nil { self.userName = trimmed }
            self.isAuthenticated = true
            self.lastError = nil
        }
    }

    func signOut() {
        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
    }

    func resetAll() {
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userName = nil
            UserDefaults.standard.removeObject(forKey: Key.isAuthenticated)
            UserDefaults.standard.removeObject(forKey: Key.userName)
        }
    }
}
