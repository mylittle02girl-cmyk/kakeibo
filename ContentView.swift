import SwiftUI

// ======================================================
// MARK: - データ
// ======================================================

/// 1拍分のデータ
struct Beat: Identifiable, Codable {

    var id = UUID()

    /// 0 = なし
    /// 1 = 表だけ
    /// 2 = 裏だけ
    /// 3 = 表・裏
    var state: Int = 0

    /// 下段の言葉
    var text: String = ""
}

/// 保存するフレーズ
struct Phrase: Identifiable, Codable {

    var id = UUID()

    var name: String

    var beats: [Beat]
}

// ======================================================
// MARK: - 端末への保存
// ======================================================

/// 譜面とフレーズを端末（UserDefaults）に保存・読み込みする
enum Storage {

    private static let beatsKey = "savedBeats"
    private static let phrasesKey = "savedPhrases"

    static let beatCount = 8

    // 8拍ぶんの空の譜面
    static func emptyBeats() -> [Beat] {
        (0..<beatCount).map { _ in Beat() }
    }

    // ---------- 譜面 ----------
    static func saveBeats(_ beats: [Beat]) {
        save(beats, key: beatsKey)
    }

    static func loadBeats() -> [Beat] {
        guard
            let beats = load([Beat].self, key: beatsKey),
            beats.count == beatCount
        else {
            return emptyBeats()
        }
        return beats
    }

    // ---------- フレーズ ----------
    static func savePhrases(_ phrases: [Phrase]) {
        save(phrases, key: phrasesKey)
    }

    static func loadPhrases() -> [Phrase] {
        load([Phrase].self, key: phrasesKey) ?? []
    }

    // ---------- 共通 ----------
    private static func save<T: Encodable>(
        _ value: T,
        key: String
    ) {
        guard let data = try? JSONEncoder().encode(value) else {
            return
        }
        UserDefaults.standard.set(data, forKey: key)
    }

    private static func load<T: Decodable>(
        _ type: T.Type,
        key: String
    ) -> T? {
        guard
            let data = UserDefaults.standard.data(forKey: key)
        else {
            return nil
        }
        return try? JSONDecoder().decode(type, from: data)
    }
}

// ======================================================
// MARK: - 下段の候補
// ======================================================

let wordCandidates = [
    "テン",
    "テケ",
    "テテ",
    "スッ",
    "スケ",
    "ステ",
    "スク"
]

// ======================================================
// MARK: - メイン画面
// ======================================================

struct ContentView: View {

    // 8拍（起動時に保存済みのものを読み込む）
    @State private var beats: [Beat] =
        Storage.loadBeats()

    // 保存したフレーズ（起動時に読み込む）
    @State private var phrases: [Phrase] =
        Storage.loadPhrases()

    // --------------------------------------------------
    // 下段の入力
    // --------------------------------------------------

    @State private var showingWordPicker = false
    @State private var editingBeatIndex = 0

    // --------------------------------------------------
    // 自由入力
    // --------------------------------------------------

    @State private var showingFreeText = false
    @State private var freeText = ""

    // --------------------------------------------------
    // フレーズ保存
    // --------------------------------------------------

    @State private var showingPhraseRange = false
    @State private var phraseStart = 0
    @State private var phraseEnd = 7

    @State private var showingPhraseName = false
    @State private var phraseName = ""

    // --------------------------------------------------
    // フレーズ挿入
    // --------------------------------------------------

    @State private var showingPhraseList = false
    @State private var showingInsertPosition = false
    @State private var insertPosition = 0

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                // ======================================
                // タイトル
                // ======================================

                Text("太鼓譜面")
                    .font(.largeTitle)
                    .bold()

                // ======================================
                // 譜面
                // ======================================

                ScrollView(.horizontal) {

                    VStack(spacing: 0) {

                        // ------------------------------
                        // 上段
                        // ------------------------------

                        HStack(spacing: 0) {

                            ForEach(beats.indices, id: \.self) { index in

                                Button {

                                    changeBeatState(index)

                                } label: {

                                    Text(
                                        symbol(
                                            for: beats[index].state
                                        )
                                    )
                                    .font(.title2)
                                    .frame(
                                        width: 70,
                                        height: 50
                                    )
                                    .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)
                                .overlay(
                                    Rectangle()
                                        .stroke(
                                            .gray,
                                            lineWidth: 1
                                        )
                                )
                            }
                        }

                        // ------------------------------
                        // 下段
                        // ------------------------------

                        HStack(spacing: 0) {

                            ForEach(beats.indices, id: \.self) { index in

                                Button {

                                    editingBeatIndex = index
                                    showingWordPicker = true

                                } label: {

                                    Text(
                                        beats[index].text
                                    )
                                    .font(.body)
                                    .frame(
                                        width: 70,
                                        height: 50
                                    )
                                    .foregroundStyle(.primary)
                                }
                                .buttonStyle(.plain)
                                .overlay(
                                    Rectangle()
                                        .stroke(
                                            .gray,
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }
                    .padding()
                }

                Divider()

                // ======================================
                // フレーズ保存
                // ======================================

                Button {

                    phraseStart = 0
                    phraseEnd = 7
                    showingPhraseRange = true

                } label: {

                    Label(
                        "フレーズを保存",
                        systemImage: "bookmark"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                // ======================================
                // フレーズ挿入
                // ======================================

                Button {

                    insertPosition = 0
                    showingInsertPosition = true

                } label: {

                    Label(
                        "フレーズを挿入",
                        systemImage: "rectangle.stack"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                Spacer()
            }
            .padding()

            // ==========================================
            // 下段の候補選択
            // ==========================================

            .sheet(
                isPresented: $showingWordPicker
            ) {

                WordPickerView(

                    currentText:
                        beats[editingBeatIndex].text,

                    onSelect: { word in

                        beats[editingBeatIndex].text = word
                        Storage.saveBeats(beats)
                        showingWordPicker = false
                    },

                    onFreeText: {

                        freeText =
                            beats[editingBeatIndex].text

                        showingWordPicker = false
                        showingFreeText = true
                    }
                )
            }

            // ==========================================
            // 自由入力
            // ==========================================

            .sheet(
                isPresented: $showingFreeText
            ) {

                FreeTextView(

                    text: $freeText,

                    onSave: {

                        beats[editingBeatIndex].text =
                            freeText

                        Storage.saveBeats(beats)
                        showingFreeText = false
                    }
                )
            }

            // ==========================================
            // フレーズ範囲選択
            // ==========================================

            .sheet(
                isPresented: $showingPhraseRange
            ) {

                PhraseRangeView(

                    start: $phraseStart,
                    end: $phraseEnd,

                    onNext: {

                        showingPhraseRange = false
                        phraseName = ""
                        showingPhraseName = true
                    }
                )
            }

            // ==========================================
            // フレーズ名
            // ==========================================

            .alert(
                "フレーズ名",
                isPresented: $showingPhraseName
            ) {

                TextField(
                    "例：基本パターン",
                    text: $phraseName
                )

                Button("保存") {
                    savePhrase()
                }

                Button(
                    "キャンセル",
                    role: .cancel
                ) {}
            }

            // ==========================================
            // フレーズ挿入位置
            // ==========================================

            .sheet(
                isPresented: $showingInsertPosition
            ) {

                InsertPositionView(

                    position: $insertPosition,

                    onNext: {

                        showingInsertPosition = false
                        showingPhraseList = true
                    }
                )
            }

            // ==========================================
            // フレーズ一覧
            // ==========================================

            .sheet(
                isPresented: $showingPhraseList
            ) {

                PhraseListView(

                    phrases: $phrases,

                    onSelect: { phrase in

                        insertPhrase(
                            phrase,
                            at: insertPosition
                        )

                        showingPhraseList = false
                    },

                    // 削除したときも保存し直す
                    onChange: {
                        Storage.savePhrases(phrases)
                    }
                )
            }
        }
    }

    // ==================================================
    // MARK: - 上段の○を変更
    // ==================================================

    func changeBeatState(_ index: Int) {

        beats[index].state += 1

        if beats[index].state > 3 {
            beats[index].state = 0
        }

        Storage.saveBeats(beats)
    }

    // ==================================================
    // MARK: - ○の表示
    // ==================================================

    func symbol(for state: Int) -> String {

        switch state {

        case 1:
            return "○ "

        case 2:
            return " ○"

        case 3:
            return "○○"

        default:
            return "  "
        }
    }

    // ==================================================
    // MARK: - フレーズ保存
    // ==================================================

    func savePhrase() {

        guard !phraseName.isEmpty else {
            return
        }

        let selectedBeats = Array(
            beats[phraseStart...phraseEnd]
        )

        let phrase = Phrase(
            name: phraseName,
            beats: selectedBeats
        )

        phrases.append(phrase)

        Storage.savePhrases(phrases)
    }

    // ==================================================
    // MARK: - フレーズ挿入
    // ==================================================

    func insertPhrase(
        _ phrase: Phrase,
        at position: Int
    ) {

        let count = phrase.beats.count

        // 8拍を超える場合は入れない
        guard position + count <= 8 else {
            return
        }

        for i in 0..<count {

            beats[position + i] =
                phrase.beats[i]
        }

        Storage.saveBeats(beats)
    }
}

// ======================================================
// MARK: - 下段候補選択
// ======================================================

struct WordPickerView: View {

    let currentText: String
    let onSelect: (String) -> Void
    let onFreeText: () -> Void

    var body: some View {

        NavigationStack {

            List {

                // 空欄
                Button {

                    onSelect("")

                } label: {

                    HStack {

                        Text("空欄")

                        Spacer()

                        if currentText.isEmpty {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                // 候補
                ForEach(
                    wordCandidates,
                    id: \.self
                ) { word in

                    Button {

                        onSelect(word)

                    } label: {

                        HStack {

                            Text(word)

                            Spacer()

                            if currentText == word {

                                Image(
                                    systemName:
                                        "checkmark"
                                )
                            }
                        }
                    }
                }

                // 自由入力
                Button {

                    onFreeText()

                } label: {

                    Label(
                        "自由入力",
                        systemImage: "keyboard"
                    )
                }
            }
            .navigationTitle("言葉を選択")
        }
    }
}

// ======================================================
// MARK: - 自由入力画面
// ======================================================

struct FreeTextView: View {

    @Binding var text: String

    let onSave: () -> Void

    var body: some View {

        NavigationStack {

            VStack {

                TextField(
                    "言葉を入力",
                    text: $text
                )
                .textFieldStyle(.roundedBorder)
                .font(.title2)
                .padding()

                Spacer()
            }
            .navigationTitle("自由入力")
            .toolbar {

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("保存") {
                        onSave()
                    }
                }
            }
        }
    }
}

// ======================================================
// MARK: - フレーズ範囲選択
// ======================================================

struct PhraseRangeView: View {

    @Binding var start: Int
    @Binding var end: Int

    let onNext: () -> Void

    var body: some View {

        NavigationStack {

            VStack(spacing: 25) {

                Text("保存する範囲")
                    .font(.title2)
                    .bold()

                Text(
                    "\(start + 1)拍目 ～ \(end + 1)拍目"
                )
                .font(.title3)

                Stepper(
                    "開始：\(start + 1)拍目",
                    value: $start,
                    in: 0...end
                )

                Stepper(
                    "終了：\(end + 1)拍目",
                    value: $end,
                    in: start...7
                )

                Spacer()

                Button("次へ") {
                    onNext()
                }
                .buttonStyle(
                    .borderedProminent
                )
            }
            .padding()
            .navigationTitle("フレーズ範囲")
        }
    }
}

// ======================================================
// MARK: - フレーズ挿入位置
// ======================================================

struct InsertPositionView: View {

    @Binding var position: Int

    let onNext: () -> Void

    var body: some View {

        NavigationStack {

            VStack(spacing: 25) {

                Text("挿入する位置")
                    .font(.title2)
                    .bold()

                Picker(
                    "位置",
                    selection: $position
                ) {

                    ForEach(0..<8) { index in

                        Text(
                            "\(index + 1)拍目"
                        )
                        .tag(index)
                    }
                }
                .pickerStyle(.wheel)

                Button("フレーズを選ぶ") {
                    onNext()
                }
                .buttonStyle(
                    .borderedProminent
                )
            }
            .padding()
            .navigationTitle("挿入位置")
        }
    }
}

// ======================================================
// MARK: - フレーズ一覧
// ======================================================

struct PhraseListView: View {

    @Binding var phrases: [Phrase]

    let onSelect: (Phrase) -> Void

    /// 一覧が変更されたとき（削除など）に呼ばれる
    let onChange: () -> Void

    var body: some View {

        NavigationStack {

            List {

                if phrases.isEmpty {

                    Text(
                        "保存されたフレーズはありません"
                    )
                    .foregroundStyle(.secondary)

                } else {

                    ForEach(phrases) { phrase in

                        Button {

                            onSelect(phrase)

                        } label: {

                            VStack(
                                alignment: .leading,
                                spacing: 5
                            ) {

                                Text(phrase.name)
                                    .font(.headline)

                                Text(
                                    "\(phrase.beats.count)拍"
                                )
                                .font(.caption)
                                .foregroundStyle(
                                    .secondary
                                )
                            }
                        }
                    }
                    .onDelete { indexSet in

                        phrases.remove(
                            atOffsets: indexSet
                        )

                        onChange()
                    }
                }
            }
            .navigationTitle("フレーズ")
        }
    }
}
