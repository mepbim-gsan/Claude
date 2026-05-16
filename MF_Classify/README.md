# MF 分類アシスタント

MoneyForwardの家計簿分類に迷ったとき、支出・収入の内容を入力するだけでAIが最適な分類を提案してくれるWebアプリです。

## 機能

- **分類チャット** — 入力内容に対してClaude AIが大分類・中分類・理由を提案
- **分類管理** — 大分類・中分類のCRUD（標準分類24件を初期内蔵）
- **Firebase共有** — Googleログインで家族間データ共有
- **オフライン対応** — キャッシュがあれば未接続でもチャット機能が動作

## セットアップ

### 1. Firebase プロジェクトの準備

1. [Firebase Console](https://console.firebase.google.com) でプロジェクトを作成
2. **Authentication** → ログイン方法 → **Google** を有効化
3. **Firestore Database** → データベースを作成（本番モードで開始）
4. **プロジェクト設定** → ウェブアプリを追加 → 設定情報をコピー

#### 承認済みドメインの追加

Authentication → Settings → 承認済みドメイン に `localhost` を追加してください（ローカル開発時）。

#### Firestore セキュリティルール

Firebase Console → Firestore → **ルール** タブで以下を設定します：

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /categories/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 2. Claude API キーの取得

[Anthropic Console](https://console.anthropic.com) でAPIキーを発行してください。

### 3. アプリの起動

Google認証にはHTTP(S)サーバーが必要です。`file://` では動作しません。

```bash
# Python
python3 -m http.server 8080

# Node.js (npx)
npx serve .

# VS Code
# Live Server 拡張機能を使用
```

ブラウザで `http://localhost:8080/MF_Classify/` を開きます。

### 4. 初期設定手順

1. **⚙️ 設定タブ** を開く
2. **Claude APIキー** を入力 → 「保存」
3. **Firebase設定**（6項目）を入力 → 「設定を保存して接続」
4. ヘッダーの **「Googleログイン」** をクリックしてサインイン
5. **設定タブ → 「↑ Firebaseへ保存」** で初期分類データを同期

### 5. 家族との共有

同じFirebaseプロジェクトの設定情報を家族のデバイスにも入力してGoogleログインすれば、分類データを共有できます。

## 使い方

### 分類チャット

支出・収入の内容をテキスト入力して送信すると、AIが適切な分類を提案します。

| 入力例 | 提案 |
|--------|------|
| スーパーで食料品を買った | 食費 / 食料品 |
| Netflixの月額料金 | 趣味・娯楽 / 娯楽 |
| 電車で通勤した | 交通費 / 電車・バス |
| 歯医者に行った | 健康・医療 / 医療費 |

`Shift+Enter` で改行、`Enter` で送信します。

### 分類管理

- フィルタで支出・収入を切り替え
- 大分類のアコーディオンを開いて中分類を確認
- ✏️ で名前・種別を編集、🗑️ / ✕ で削除

変更後は **「↑ Firebaseへ保存」** を実行して家族と同期してください。

## ファイル構成

```
MF_Classify/
└── index.html    # 単一HTMLファイル（HTML + CSS + JavaScript）
```

## 技術スタック

| 項目 | 技術 |
|------|------|
| フロントエンド | HTML / CSS / Vanilla JS |
| AI | Anthropic Claude API |
| データ保存 | Firebase Firestore |
| 認証 | Firebase Authentication（Google） |
| 設定保存 | localStorage |

## 注意事項

- Claude APIキー・Firebase設定は **localStorage にのみ保存** されます。HTMLソースには含まれません。
- Firebase はクライアントサイドのみで使用します（Cloud Functions 不使用）。
- Firestoreのセキュリティルールは **必ず設定**してください（未設定だと誰でも読み書き可能になります）。
- APIキーの不正利用防止のため、ClaudeとFirebase双方でIPや利用制限を設定することを推奨します。
