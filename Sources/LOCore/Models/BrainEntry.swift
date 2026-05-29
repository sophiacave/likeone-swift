import Foundation

public struct BrainEntry: Codable, Identifiable, Sendable {
    public let id: UUID
    public let key: String
    public let category: String
    public let description: String
    public let value: String
    public let priority: Int
    public let updatedAt: Date

    public init(
        id: UUID = UUID(),
        key: String,
        category: String = "session",
        description: String,
        value: String,
        priority: Int = 5,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.key = key
        self.category = category
        self.description = description
        self.value = value
        self.priority = priority
        self.updatedAt = updatedAt
    }
}
