import SwiftUI

/// 翻訳履歴の一覧。タップで本画面に呼び戻し、スワイプで削除、全消去にも対応。
struct MobileHistoryView: View {
    @EnvironmentObject var history: HistoryStore
    @Environment(\.dismiss) private var dismiss

    /// 履歴を選んだときに本画面へ呼び戻すためのコールバック。
    var onSelect: (HistoryItem) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if history.items.isEmpty {
                    ContentUnavailableView(
                        "履歴はありません",
                        systemImage: "clock",
                        description: Text("翻訳すると、ここに最近の結果が残ります。")
                    )
                } else {
                    List {
                        ForEach(history.items) { item in
                            Button {
                                onSelect(item)
                                dismiss()
                            } label: {
                                row(item)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { history.delete($0) }
                    }
                }
            }
            .navigationTitle("履歴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !history.items.isEmpty {
                        Button("全消去", role: .destructive) { history.clear() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .tint(Brand.green)
        }
    }

    private func row(_ item: HistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(item.direction.headerText)
                    .font(.caption2).bold()
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Brand.green.opacity(0.15))
                    .clipShape(Capsule())
                Spacer()
                Text(item.date, format: .dateTime.month().day().hour().minute())
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Text(item.sourceText)
                .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            Text(item.translatedText)
                .font(.body).lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}
