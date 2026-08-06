# Screen Capture Memo

画面共有→範囲固定→連写キャプチャ+メモを記録し、自己完結型HTML（一覧/A4グリッド/ノート形式、印刷・PDF対応）として書き出すWebツールです。

## 機能

- `getDisplayMedia` による画面共有 → 範囲固定（比率指定 or 全画面ワンクリック）
- 📸キャプチャ / 📋クリップボード貼り付け / 📝見出しメモ を記録一覧に追加
- 記録一覧でのメモ編集・並び替え（ドラッグ&ドロップ）・トリミング（非破壊）
- Document Picture-in-Picture APIによる常時表示ウィンドウ（他アプリ操作中もキャプチャ可能）
- 「HTML保存」で自己完結型HTMLとして書き出し（一覧/A4グリッド/ノート形式、印刷・PDF向けレイアウト対応）
- 書き出したHTMLは「インポート」で再読み込みし、続きから編集可能

## 使い方

GitHub Pages でホスティングしているため、以下のURLからアクセスできます。

```
https://mepbim-gsan.github.io/Claude/Screen_Capture_Memo/screen-capture-memo.html
```

データはブラウザ内 IndexedDB にのみ保存され、サーバーへの送信はありません。

## 対象ブラウザ

Edge / Chrome 限定（`getDisplayMedia`・Document Picture-in-Picture API・File System Access API 等を使用）。
`https://` または `localhost` 等の secureContext でのみ動作します（社内イントラ等の `http://` では画面共有機能が動作しません）。

## 技術スタック

- HTML / CSS / Vanilla JS（単一ファイル、ビルド不要、外部ライブラリ依存なし）
- IndexedDB（`screen-capture-memo-db`）
- GitHub Pages

## 開発メモ

このツール固有の技術情報（データモデル、埋め込みexportHtmlの取り扱い上の注意、開発経緯など）は Knowledge リポジトリの `knowledge/Repo_Claude-Screen_Capture_Memo.md` を参照してください。
