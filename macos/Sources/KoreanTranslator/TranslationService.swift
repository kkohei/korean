import Foundation

/// 翻訳の方向。
enum TranslationDirection: String {
    case jaToKo   // 日本語 → 韓国語
    case koToJa   // 韓国語 → 日本語

    var sourceLabel: String { self == .jaToKo ? "日本語" : "한국어" }
    var targetLabel: String { self == .jaToKo ? "한국어" : "日本語" }
    var headerText: String { "\(sourceLabel) → \(targetLabel)" }

    var inputPlaceholder: String {
        self == .jaToKo ? "> 翻訳したい日本語を入力…" : "> 번역할 한국어를 입력…"
    }
    var copyHelp: String { self == .jaToKo ? "韓国語をコピー" : "日本語をコピー" }
    var toggled: TranslationDirection { self == .jaToKo ? .koToJa : .jaToKo }
}

struct TranslationResult {
    /// 韓国語訳本文
    let korean: String
    /// 補足メモ（固有名詞の根拠・表記揺れの判断など）。無ければ nil。
    let notes: String?
}

enum TranslationError: LocalizedError {
    case missingAPIKey
    case emptyInput
    case http(Int, String)
    case decoding(String)
    case network(String)
    case noText

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "APIキーが設定されていません。⚙ボタンからAnthropic APIキーを入力してください。"
        case .emptyInput:
            return "翻訳する日本語を入力してください。"
        case .http(let code, let msg):
            return "APIエラー (\(code))：\(msg)"
        case .decoding(let m):
            return "応答の解析に失敗しました：\(m)"
        case .network(let m):
            return "通信エラー：\(m)"
        case .noText:
            return "翻訳結果を取得できませんでした。もう一度お試しください。"
        }
    }
}

/// Anthropic Messages API を使い、Web検索を併用して日本語→韓国語の翻訳を行う。
struct TranslationService {

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    private func systemPrompt(for direction: TranslationDirection) -> String {
        switch direction {
        case .jaToKo:
            return """
            あなたは日本語から韓国語へのプロの翻訳者です。ユーザーが入力した日本語を、自然で正確な韓国語に翻訳してください。

            重要なルール:
            - 固有名詞（人名・地名・会社名・商品名・作品名・専門用語・流行語・時事的表現など）が含まれる場合は、web_search ツールで実際の韓国語表記・現地での一般的な言い回しを確認してから訳すこと。推測で当て字にしない。
            - 文脈・敬語レベル・口調をできるだけ保つこと。
            - 余計な前置きや解説を出力に含めない。

            出力フォーマット（厳守）:
            1行目以降に韓国語訳のみを書く。
            補足が必要な場合（固有名詞の根拠、表記の選択理由など）のみ、訳の後に独立した1行 `===NOTES===` を置き、その下に日本語で簡潔にメモを書く。補足が不要なら `===NOTES===` 自体を書かない。
            """
        case .koToJa:
            return """
            あなたは韓国語から日本語へのプロの翻訳者です。ユーザーが入力した韓国語を、自然で正確な日本語に翻訳してください。

            重要なルール:
            - 固有名詞（人名・地名・会社名・商品名・作品名・専門用語・流行語・時事的表現など）が含まれる場合は、web_search ツールで実際の日本語表記・日本での一般的な言い回しを確認してから訳すこと。推測で当て字にしない。
            - 文脈・敬語レベル・口調をできるだけ保つこと。
            - 余計な前置きや解説を出力に含めない。

            出力フォーマット（厳守）:
            1行目以降に日本語訳のみを書く。
            補足が必要な場合（固有名詞の根拠、表記の選択理由など）のみ、訳の後に独立した1行 `===NOTES===` を置き、その下に日本語で簡潔にメモを書く。補足が不要なら `===NOTES===` 自体を書かない。
            """
        }
    }

    func translate(text rawText: String,
                   direction: TranslationDirection,
                   apiKey: String,
                   model: String,
                   webSearchUses: Int) async throws -> TranslationResult {

        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw TranslationError.missingAPIKey }

        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw TranslationError.emptyInput }

        var body: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "system": systemPrompt(for: direction),
            "messages": [
                ["role": "user", "content": text]
            ]
        ]
        if webSearchUses > 0 {
            body["tools"] = [
                [
                    "type": "web_search_20250305",
                    "name": "web_search",
                    "max_uses": webSearchUses
                ]
            ]
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TranslationError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw TranslationError.network("不明な応答形式")
        }
        guard (200..<300).contains(http.statusCode) else {
            let msg = Self.extractErrorMessage(data)
                ?? String(data: data, encoding: .utf8)
                ?? "詳細不明"
            throw TranslationError.http(http.statusCode, msg)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw TranslationError.decoding("content フィールドが見つかりません")
        }

        // text タイプのブロックのみを連結（web検索の中間ブロックは無視）。
        let combined = content
            .compactMap { block -> String? in
                guard (block["type"] as? String) == "text" else { return nil }
                return block["text"] as? String
            }
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !combined.isEmpty else { throw TranslationError.noText }
        return Self.parse(combined)
    }

    /// `===NOTES===` 区切りで本文と補足メモを分離する。
    private static func parse(_ raw: String) -> TranslationResult {
        let parts = raw.components(separatedBy: "===NOTES===")
        let korean = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        if parts.count > 1 {
            let notes = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            return TranslationResult(korean: korean, notes: notes.isEmpty ? nil : notes)
        }
        return TranslationResult(korean: korean, notes: nil)
    }

    /// エラーレスポンス JSON から error.message を取り出す。
    private static func extractErrorMessage(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return nil
        }
        return message
    }
}
