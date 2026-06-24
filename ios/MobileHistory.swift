import Foundation
import Combine
import SwiftUI

/// 翻訳1件分の履歴。端末内（UserDefaults）に JSON で保存する。
struct HistoryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let directionRaw: String
    let sourceText: String
    let translatedText: String
    let notes: String?

    var direction: TranslationDirection { TranslationDirection(rawValue: directionRaw) ?? .jaToKo }

    init(date: Date, direction: TranslationDirection, sourceText: String, translatedText: String, notes: String?) {
        self.id = UUID()
        self.date = date
        self.directionRaw = direction.rawValue
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.notes = notes
    }
}

/// 翻訳履歴の保持・永続化。最近のものから最大 maxItems 件を端末に保存する。
@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [HistoryItem] = []

    private let key = "translationHistory"
    private let maxItems = 50

    init() { load() }

    func add(source: String, result: TranslationResult, direction: TranslationDirection) {
        let item = HistoryItem(
            date: Date(),
            direction: direction,
            sourceText: source.trimmingCharacters(in: .whitespacesAndNewlines),
            translatedText: result.korean,
            notes: result.notes
        )
        // 直近とまったく同じ入力・方向なら重複登録しない。
        if let first = items.first,
           first.sourceText == item.sourceText,
           first.directionRaw == item.directionRaw {
            return
        }
        items.insert(item, at: 0)
        if items.count > maxItems {
            items.removeLast(items.count - maxItems)
        }
        save()
    }

    func delete(_ offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
