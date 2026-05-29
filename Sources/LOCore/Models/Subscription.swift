import Foundation

public enum AuthProvider: String, Codable, Sendable {
    case apple
    case google
    case magicLink = "magic_link"
}

public enum SubscriptionTier: String, Codable, Sendable {
    case free
    case pro
    case founding
}
