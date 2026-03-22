# ふたりのタスク

カップル・夫婦向けの共有タスク管理Webアプリです。

## 機能

- Googleアカウントによるログインと複数デバイス間のリアルタイム同期（Firebase Firestore）
- Googleログイン不要のメンバー追加（サブアカウント的な使い方）
- タスクの作成・編集・完了管理
- 複数担当者のアサイン
- サブタスク管理（全完了で親タスクを自動完了）
- カテゴリ・タグによる分類
- 優先フラグ・期日・メモ・URL・画像添付
- スワイプ操作による編集・削除（モバイル対応）
- 定型タスク管理と手動生成（繰り返しタスクのテンプレート）
- ダッシュボード（統計・カレンダーヒートマップ・タグ分布・担当別完了数）
- フィルター（ステータス・カテゴリ・タグ・キーワード検索）
- カスタムカラーパレットによるユーザー・カテゴリの色設定
- 完了タスクのJSONエクスポート・古いタスクの一括削除
- データの全エクスポート・インポート（JSON）

## 使い方

GitHub Pages でホスティングしているため、以下のURLからアクセスできます。

```
https://mepbim-gsan.github.io/couple-tasks/couple-tasks.html
```

Googleアカウントでログインするとデータがクラウドに保存され、複数デバイス間で同期されます。

### Firebase configの初期設定

初回アクセス時（または新しいデバイスでアクセスする場合）、ログイン画面の入力欄にFirebase ConsoleのconfigをペーストしてOKです。JS形式・JSON形式どちらも対応しています。

configはブラウザのlocalStorageに保存されるため、HTMLファイルに直接記述する必要はありませんが、**新しいデバイスでアクセスするたびに入力が必要**です。以下のconfigを手元に控えておいてください。

```js
const firebaseConfig = {
  apiKey:            "YOUR_API_KEY",
  authDomain:        "YOUR_PROJECT.firebaseapp.com",
  projectId:         "YOUR_PROJECT_ID",
  storageBucket:     "YOUR_PROJECT.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId:             "YOUR_APP_ID"
};
```

## セットアップ（開発者向け）

### 必要なもの

- Firebase プロジェクト（Sparkプラン・無料）
- Firestore Database
- Firebase Authentication（Googleログイン有効）

### Firebase の設定

1. [Firebase Console](https://console.firebase.google.com) でプロジェクトを作成
2. Authentication → ログイン方法 → Google を有効化
3. Firestore Database を作成（リージョン: asia-northeast1 推奨）
4. Firestore のルールを以下に設定

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /couple-tasks/{doc} {
      allow read, write: if request.auth != null;
    }
  }
}
```

5. Authentication → 承認済みドメイン に `mepbim-gsan.github.io` を追加

## 技術スタック

- HTML / CSS / Vanilla JS（ビルド不要・単一ファイル）
- Firebase Authentication
- Firebase Firestore
- GitHub Pages
