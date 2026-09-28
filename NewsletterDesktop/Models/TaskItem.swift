import Foundation

enum Quadrant: String, Codable, CaseIterable, Identifiable {
    case `do`, schedule, delegate, eliminate
    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
    var subtitle: String { switch self { case .do: "urgent + important"; case .schedule: "not urgent + important"; case .delegate: "urgent + not important"; case .eliminate: "not urgent + not important" } }
}

struct RichRange: Codable, Equatable { var start: Int; var end: Int; var bold: Bool?; var highlight: String?; var fontSize: Double? }
struct TaskContent: Codable, Equatable { var text: String; var ranges: [RichRange] = [] }
struct TaskItem: Codable, Identifiable, Equatable {
    var id: String
    var weekOf: Date
    var completedAt: Date?
    var carriedFrom: Date?
    var quadrant: Quadrant
    var content: TaskContent

    enum CodingKeys: String, CodingKey { case id, weekOf, completedAt, carriedFrom, quadrant, content }
}
