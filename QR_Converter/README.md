# QR⇄テキスト変換

URL・テキストとQRコードを相互変換するWebツールです。

## 機能

- **テキスト入力 → QRコード生成**
  - アドレス（URL）を入力すると、開けるQRコード＋「開く」ボタンを表示
  - 文章・テキストを入力すると、コピーできる形式で表示（QRコードも併せて生成）
- **QRコード画像 → 中身を確認**
  - QRコード画像をペースト（Ctrl+V）／ドラッグ&ドロップ／ファイル選択／スマホのカメラ撮影すると、読み取った内容をURL・テキストと自動判定して表示
- コピー・QR画像保存（PNG）・最近の変換履歴（ローカル保存）

## 使い方

GitHub Pages でホスティングしているため、以下のURLからアクセスできます。

```
https://mepbim-gsan.github.io/Claude/QR_Converter/index.html
```

1. 上部の入力欄にURLやテキストを入力・ペースト、またはQRコード画像をペースト／ドロップ／「📷 カメラで撮影」で撮影
2. URLの場合はQRコードをタップ／「開く」ボタンでアクセス可能
3. テキストの場合は「コピー」ボタンでクリップボードにコピー可能
4. 履歴からは過去の変換結果を再表示できます（端末のブラウザ内にのみ保存、クラウド同期なし）

## 技術スタック

- HTML / CSS / Vanilla JS（ビルド不要）
- [qrcode-generator](https://github.com/kazuhikoarase/qrcode-generator)（QRコード生成、CDN経由）
- [jsQR](https://github.com/cozmo/jsQR)（QRコードデコード、CDN経由）
- GitHub Pages
