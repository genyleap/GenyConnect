![genyconnect-cover](https://github.com/user-attachments/assets/a65daa50-b9ce-46e4-a23b-7886b1c41258)
---
# GenyConnect

[English](../README.md) | [Persian - فارسی](README.fa.md) | [Chinese - 中文](README.zh-CN.md) | [Japanese - 日本語](README.ja.md) | [Turkish - Türkçe](README.tr.md) | [Russian - Русский](README.ru.md) | [French - Français](README.fr.md) | [Spanish - Español](README.es.md) | [Korean - 한국어](README.ko.md) | [Azerbaijani - Azərbaycanca](README.az.md) | [Hindi - हिंदी](README.hi.md) | [Portuguese - Português](README.pt.md) | [Arabic - العربية](README.ar.md) | [German - Deutsch](README.de.md)


GenyConnect は、プライベートネットワークと暗号化通信のための、モダンでクロスプラットフォーム対応の安全な接続クライアントです。高い性能、プライバシー、精密なトラフィック管理を重視して開発されています。

安全なネットワークエンジンとトンネリングエンジンのための強力なオーケストレーション層を提供し、信頼性、可観測性、運用の透明性、ユーザー体験を重視しながら、特定のプロトコル、技術、実装には依存しません。

GenyConnect は 2 つの方向で開発されています。個人ユーザーと日常的な接続ニーズに向けた Community Edition と、集中管理、ネットワークポリシー、アクセス制御、大規模な安全通信を必要とする組織向けの Commercial & Enterprise Edition です。

<p align="left">
  <a href="https://en.cppreference.com/w/cpp/23">
    <img
      alt="C++23"
      src="https://img.shields.io/badge/C%2B%2B-23-00599C?style=for-the-badge&logo=cplusplus"
    />
  </a>

  <a href="https://cmake.org/">
    <img
    alt="CMake 4.2+"
    src="https://img.shields.io/badge/CMake-4.2%2B-00599C?style=for-the-badge&logo=cmake"
    />
  </a>

  <a href="https://www.qt.io/">
    <img
      alt="Qt 6"
      src="https://img.shields.io/badge/Qt-6-41CD52?style=for-the-badge&logo=qt"
    />
  </a>

  <a href="../LICENSE">
    <img
      alt="License GPL-3.0-or-later"
      src="https://img.shields.io/badge/License-GPL--3.0--or--later-8E44AD?style=for-the-badge"
    />
  </a>

  <a href="https://github.com/thecompez/genyconnect/actions">
    <img
      alt="Build Passing"
      src="https://img.shields.io/badge/Build-Passing-27AE60?style=for-the-badge"
    />
  </a>

  <a href="https://github.com/thecompez/genyconnect/pulls">
    <img
      alt="PRs Welcome"
      src="https://img.shields.io/badge/PRs-Welcome-F39C12?style=for-the-badge"
    />
  </a>
</p>


---

## 概要

GenyConnect により、ユーザーは構造化されたサーバープロファイルと共有可能な設定リンクを使って安全な接続を確立し、管理できます。

実行時設定は動的に生成され、接続ライフサイクルは明示的に監視され、システム状態は常に完全に観測可能です。

このプラットフォームは意図的にエンジン非依存で設計されており、ユーザーのワークフローや期待される動作を変えずに、さまざまなトンネリングバックエンドを統合できます。

GenyConnect は、一般的なトンネリング用途だけに限られたものではありません。長期的には、サービス、プライベートインフラ、クラウドリソース、安定した信頼性の高い通信を必要とする分散チームへのアクセスを管理する、知的な接続レイヤーを目指しています。

1.4 から 1.5 のリリース範囲で、GenyConnect はより広い一般利用に向けて成熟し、信頼できる接続を必要とするユーザーの多くの要件を満たすことが見込まれています。今後のリリースでは Persian と追加のアプリ内言語の対応も予定されています。

第2世代の GenyConnect は、アクセス管理、通信インフラのカスタマイズ、ネットワーク回復力、外部サービスへの依存低減、さまざまなネットワーク条件での安定接続など、商用および組織向けのニーズにより深く焦点を当てます。将来のバージョンでは、プライベートネットワークと組織アクセスを定義、管理するための専用 `gen.` 形式と GenyConnect 独自の通信アーキテクチャもサポートする予定です。

---

## 主な機能

- 明確な運用可視性
  - ライブログ
  - リアルタイムのトラフィック統計
  - 明示的な接続状態レポート

- 高性能な実行
  - 軽量なランタイム
  - 最小限のオーバーヘッド
  - 継続的な負荷下でも高い応答性

- 決定的なライフサイクル管理
  - 予測可能な起動
  - クリーンな終了
  - 安全な再接続ロジック

- 高度なトラフィックルーティング
  - ホワイトリストベースのルーティング
  - ドメイン単位の tunnel/direct/block ルール
  - 対応環境でのアプリケーションベースルーティング
  - 対応環境でのプロセスベースルーティング

- 柔軟なトンネリングモード
  - アプリケーションレベルのプロキシ
  - システム全体のトンネリング
  - 一貫した制御画面

- LAN Sharing
  - GenyConnect が管理するトラフィックをローカルネットワーク上の他のデバイスと共有
  - ゲーム機、スマートテレビ、スマートフォン、タブレット、ノートPC、デスクトップPCなどに対応
  - 管理されたネットワーク環境向けの高度な共有制御

- クロスプラットフォームアーキテクチャ
  - 共有ランタイムコア
  - デスクトップおよびモバイルアダプター
  - プラットフォーム固有の統合

---

## Power Mode

GenyConnect には、継続的なワークロード中の接続安定性とランタイムの一貫性を高めるために設計された、プラットフォーム対応の Power Mode システムが含まれています。

Power Mode は、強力な省電力動作、バックグラウンド制限、アイドル時の一時停止、スリープ状態への移行によるオペレーティングシステムの干渉を軽減します。

オペレーティングシステムとランタイムバックエンドに応じて、Power Mode は次の効果をもたらす場合があります。

- 重要なネットワーク経路の応答性を維持する
- 予期しない切断を減らす
- スループットの一貫性を高める
- 長時間のトラフィックセッションを最適化する
- 高負荷時のレイテンシ急増を抑える
- トンネリング中のランタイム信頼性を高める

Power Mode の動作は適応的であり、プラットフォーム機能やオペレーティングシステムの制限によって異なる場合があります。

---

## スクリーンショット

<img width="413" alt="GenyConnect screenshot 1" src="https://github.com/user-attachments/assets/c3c4fa7b-997c-4968-a019-ec8f1a88a7a1" />

<img width="422" alt="GenyConnect screenshot 2" src="https://github.com/user-attachments/assets/e8996ce9-1064-4754-8b4b-5d3c83009fa4" />

---

## プラットフォーム対応

GenyConnect は現在、次のプラットフォームをサポートしています。

- macOS
- Windows
- Linux
- Android

iOS 対応は活発に開発中です。

---

## 技術スタック

- C++23
- Qt 6 / QML
- クロスプラットフォームのネイティブランタイムアーキテクチャ
- マルチプラットフォーム展開パイプライン
- エンジン非依存のトンネリングバックエンド統合

---

## ライセンス

GenyConnect Community Edition は、GNU General Public License バージョン 3 以降（GPL-3.0-or-later）の下でライセンスされています。

商用ライセンスは、Genyleap Labs から別途提供されます。対象は次のとおりです。

- プロプライエタリな展開
- クローズドソースでの再配布
- エンタープライズ統合
- white-label 製品
- App Store 配布
- 商用エディション
- Pro または Enterprise 機能

明示的に別段の記載がない限り、以下は GPL ライセンスの対象外であり、All Rights Reserved として扱われます。

- GenyConnect の名称
- ロゴ
- アイコン
- スクリーンショット
- ビジュアルデザイン
- ブランディング資産
- プロモーション用グラフィック
- UI アートワーク
- ビジュアルアイデンティティ素材
- マーケティング資産

フォークおよび再配布は、Genyleap Labs による承認または提携を、明示的な書面許可なく示唆してはなりません。

ライセンスの詳細は LICENSE および NOTICE ファイルを参照してください。

### ライセンス概要

Community Edition ソースコード:
- GPL-3.0-or-later

商用ライセンス:
- 別個のプロプライエタリ商用ライセンス

ブランディングおよび非コード資産:
- All Rights Reserved

---

## ❤️ GenyConnect を支援

GenyConnect は Genyleap Labs によって独立して開発されているプロジェクトです。

GenyConnect が役に立つ場合は、Base Network 上の $GENY または USDC による寄付で継続的な開発を支援できます。

支援は次の用途に役立ちます。

- 継続的な開発
- セキュリティ改善
- デスクトップおよびモバイルプラットフォーム対応
- インフラストラクチャとテスト
- 将来のオープンソースリリース
- 長期的なエコシステム成長

---

## 🌐 $GENY で支援

$GENY で寄付することで、GenyConnect の開発と、より広い Geny エコシステムの両方を支援できます。

### Base Mainnet

GENY トークンコントラクト:

`0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B`

開発者寄付ウォレット:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

### Genyleap エコシステム向けに $GENY を購入またはスワップ

https://app.uniswap.org/swap?chain=base&outputCurrency=0x2a3d6f8c1fc4AcDcf3A75d19b445bae02F03676B

---

## 💵 USDC で支援

USDC は、開発を直接支援するための安定したシンプルな方法です。

### Base Mainnet

開発者寄付ウォレット:

`0x9b9E187C1B10A88C04F21A5F9DE0Ff1CA46AA589`

---

## 寄付に関する注意

寄付は GenyConnect の開発を支援するための任意の貢献です。

寄付は次のものを意味しません。

- 投資
- 株式
- 所有権
- 収益分配
- 証券
- 金融商品
- 金銭的リターンの約束

📢 開発アップデート、告知、今後のリリースは Telegram と Farcaster でフォローできます。

• Telegram: https://t.me/compezeth
• Telegram: https://t.me/genyleap
• X/Twitter: https://x.com/genyleap
• Farcaster: https://farcaster.xyz/compez.eth
• Farcaster: https://farcaster.xyz/genyleap

皆さまのフィードバックと支援は、GenyConnect とより広い Genyleap エコシステムの未来を形作る助けになります。 🚀
