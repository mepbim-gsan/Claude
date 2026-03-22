# 値段メモ帳

日用品・食品の価格を記録して単位あたりのコストを比較するWebアプリです。

## 機能

- 商品・お店のマスタ管理
- 価格・数量・単位・税区分を入力して単位単価を自動計算
- 過去の記録から商品ごとの最安値を比較
- 商品選択時に過去の単位を自動セット
- Google ログインによる複数デバイス間のリアルタイム同期（Firebase Firestore）

## 使い方

GitHub Pages でホスティングしているため、以下のURLからアクセスできます。

```
https://mepbim-gsan.github.io/Claude/Price-memo/price-memo.html
```

Googleアカウントでログインするとデータがクラウドに保存され、複数デバイス間で同期されます。未ログインの場合はブラウザのlocalStorageにのみ保存されます。

### Firebase configの初期設定

初回アクセス時（または新しいデバイスでアクセスする場合）、設定タブ →「Firebase configを入力」からFirebase ConsoleのconfigをペーストしてOKです。JS形式・JSON形式どちらも対応しています。

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
    match /users/{uid}/data/{doc} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

5. Authentication → 承認済みドメイン に `mepbim-gsan.github.io` を追加

## 技術スタック

- HTML / CSS / Vanilla JS（ビルド不要）
- Firebase Authentication
- Firebase Firestore
- GitHub Pages
