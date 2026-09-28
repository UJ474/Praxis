import SwiftUI

struct NewsletterView: View {
    let entry: NewsletterEntry
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack { Text("3 — 2 — 1").font(.system(size: 11, weight: .semibold, design: .monospaced)); Spacer(); Text(entry.weekOf, format: .dateTime.month(.abbreviated).day().year()).font(.system(size: 10, design: .monospaced)) }
                    .foregroundStyle(.secondary)
                Text(entry.topics.joined(separator: " · ")).font(.custom("New York", size: 25, relativeTo: .title2)).lineSpacing(3)
                Hairline()
                SectionHeading(number: "03", title: "Ideas from me")
                ForEach(Array(entry.ideas.enumerated()), id: \.offset) { index, idea in
                    HStack(alignment: .firstTextBaseline, spacing: 12) { Text(roman(index + 1)).font(.system(size: 10, design: .monospaced)).foregroundStyle(.orange); Text(idea).font(.custom("New York", size: 16)).lineSpacing(4) }
                }
                Hairline()
                SectionHeading(number: "02", title: "Quotes from others")
                ForEach(Array(entry.quotes.enumerated()), id: \.offset) { _, quote in
                    VStack(alignment: .leading, spacing: 5) { Text(quote.attribution).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary); Text("“\(quote.quote)”").font(.custom("New York", size: 15)).italic().lineSpacing(3); Text(quote.source).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary) }
                }
                Hairline()
                SectionHeading(number: "01", title: "Question for you")
                if let attribution = entry.question.attribution { Text(attribution).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary) }
                Text("“\(entry.question.text)”").font(.custom("New York", size: 18)).lineSpacing(4)
                Link("Read the issue ↗", destination: URL(string: entry.issueURL)!).font(.system(size: 10, design: .monospaced)).foregroundStyle(.orange).padding(.top, 6)
            }
        }.scrollIndicators(.hidden)
    }
    private func roman(_ n: Int) -> String { ["I", "II", "III"][n - 1] }
}

struct SectionHeading: View { let number: String; let title: String; var body: some View { HStack(spacing: 8) { Text(number).foregroundStyle(.orange); Text(title.uppercased()) }.font(.system(size: 10, weight: .semibold, design: .monospaced)) } }
struct Hairline: View { var body: some View { Rectangle().fill(.primary.opacity(0.22)).frame(height: 0.5).padding(.vertical, 2) } }
