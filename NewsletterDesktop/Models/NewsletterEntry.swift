import Foundation

struct NewsletterEntry: Codable, Identifiable, Equatable {
    struct Quote: Codable, Equatable { let attribution: String; let quote: String; let source: String }
    struct Question: Codable, Equatable { let attribution: String?; let text: String }
    var id: String { issueURL }
    let receivedDate: Date
    let weekOf: Date
    let issueURL: String
    let topics: [String]
    let ideas: [String]
    let quotes: [Quote]
    let question: Question

    enum CodingKeys: String, CodingKey { case receivedDate, weekOf, issueURL = "issueUrl", topics, ideas, quotes, question }

    static let preview = NewsletterEntry(receivedDate: .now, weekOf: .now, issueURL: "https://jamesclear.com/3-2-1", topics: ["seeing opportunity", "the power of volume", "big decisions"], ideas: ["Mental toughness grows when you find a subject worth caring deeply about.", "To notice opportunity, study a field that is far from your own.", "The person with one chance needs everything to go right. Give yourself many chances."], quotes: [.init(attribution: "Hunter S. Thompson on going for it", quote: "Who is the happier man: he who has braved the storm of life and lived, or he who has stayed securely on shore and merely existed?", source: "Security (1955)"), .init(attribution: "Ursula K. Le Guin on process", quote: "It is good to have an end to journey toward; but it is the journey that matters, in the end.", source: "The Left Hand of Darkness")], question: .init(attribution: "Isabel Unraveled", text: "Would choosing this make me feel more alive?"))
}
