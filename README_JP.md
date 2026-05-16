# embedded-code-skill

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License: MIT" />
  <img src="https://img.shields.io/badge/language-C-A8B9CC?style=flat-square&logo=c&logoColor=white" alt="C" />
  <img src="https://img.shields.io/badge/Claude%20Code-5678a0?style=flat-square&logo=anthropic&logoColor=white" alt="Claude Code" />
  <img src="https://img.shields.io/badge/Cursor-7C3AED?style=flat-square&logo=cursor&logoColor=white" alt="Cursor" />
  <img src="https://img.shields.io/static/v1?label=&message=VSCode&logo=visualstudiocode&logoColor=ffffff&color=007ACC&style=flat-square" alt="VSCode" />
  <img src="https://img.shields.io/badge/RTOS-FreeRTOS%20%7C%20Zephyr%20%7C%20RT--Thread-orange?style=flat-square" alt="RTOS" />
</p>

> ドライバ骨格の作成、既存コードの整理、低レベルファームウェアのレビュー、RTOS ガイダンス、ビルドシステム設定、IDE / agent 向けルール調整に使う Embedded C コード助手。

[简体中文](README.md) · [English](README_EN.md) · [日本語](README_JP.md)

---

## このリポジトリについて

このリポジトリのルール入口は `SKILL.md` だけです。

`SKILL.md` は、次の作業でモデルの出力を安定させ、保守的でレビューしやすくします：

- 新しい Embedded C ドライバ骨格を書く（関数レベルテンプレート付き）
- 既存の driver、HAL/BSP、register-access code を整理する
- ISR、DMA、cache、volatile、race、timeout、overflow のリスクをレビューする
- RTOS タスク設計、スレッドセーフ、優先度逆転防止をガイドする
- ビルドシステム設定（CMake クロスコンパイル、リンカスクリプト、スタートアップコード）をガイドする
- HAL 層テストとオンターゲットデバッグ戦略をガイドする
- リポジトリコードが本スキル規則に合致すればそのまま使用し、合致しなければ論理を変えずに規則に統一
- 同じルールを Cursor、VS Code、Claude 互換 agent、または `AGENTS.md` 向けに取り出す

これはベンダーのリファレンスマニュアル、実際のレジスタマップ、IRQ、barrier、cache/DMA ルール、タイミング要件、認証資料の代替ではありません。

---

## クイックスタート

```bash
/ecs STM32 UART ドライバを生成、ベースアドレス 0x4000C000
/ecs この SPI 初期化コードを整理し、レジスタ書き込み順序を保つ
/ecs この DMA ISR の race、volatile、cache 問題をレビューする
/ecs Cursor .cursor/rules/*.mdc 向けのルール内容を生成する
/ecs FreeRTOS タスク優先度とスタックサイズを設計する
/ecs CMake クロスコンパイル設定とリンカスクリプトを作成する
```

---

## 作業モード

| モード | 用途 |
|--------|------|
| `GENERATE` | 最小で保守しやすい module を書く。hardware facts が足りない場合は placeholder を明示する |
| `REWRITE` | public behavior、ABI、register write order、timing-sensitive sequence を保って整理する |
| `REVIEW` | finding を先に出し、correctness、hardware behavior、race、portability risk を優先する |
| `INSTALL` / `ADAPT` | `SKILL.md` のルールを対象 IDE / agent の指示ファイルに変換する |

---

## Skill アーキテクチャ

`SKILL.md` は単一入口です。構成は、request classification、repository context、work mode、subdomain rules、output contract の順に整理しています。

```mermaid
%%{init: {"flowchart": {"curve": "step"}} }%%
flowchart TB
    A([ユーザーリクエスト])
    B[SKILL.md 単一入口]
    C[Repository context を読む]
    D[Hardware fact boundary を確認]
    E{Select work mode}
    F[GENERATE: smallest module + placeholders]
    G[REWRITE: behavior / ABI / register write order を保つ]
    H[REVIEW: findings first / risk ordered]
    I[INSTALL / ADAPT: target-repo instructions を生成]
    J[Subdomain rules を適用]
    K[Coding Standards]
    L[Driver Templates]
    M[Architecture Rules]
    N[RTOS Guidance]
    O[Build System]
    P[Test & Debug]
    Q[Industry Domains]
    R[Final output contract]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    E --> G
    E --> H
    E --> I
    F --> J
    G --> J
    H --> J
    I --> R
    J --> K
    J --> L
    J --> M
    J --> N
    J --> O
    J --> P
    J --> Q
    K --> R
    L --> R
    M --> R
    N --> R
    O --> R
    P --> R
    Q --> R
```

---

## 機能マトリクス

| レイヤー | カバー範囲 |
|----------|------------|
| Entry | frontmatter（triggers、command name）を含む単一 `SKILL.md` |
| Context | local headers、macros、status types、naming、SDKs、build flags、existing drivers |
| Fact boundary | `USER_PROVIDED`、`REPO_DERIVED`、`PLACEHOLDER` を明示し、hardware details を推を推測しない |
| Work modes | `GENERATE`、`REWRITE`、`REVIEW`、`INSTALL`、`ADAPT` |
| Output contracts | generated code、rewrite、review findings、IDE instructions の出力形 |
| Coding standards | naming、types、error handling、struct patterns、comments、dynamic allocation limits（重複除去済み） |
| Driver templates | UART、SPI、I2C、DMA、CAN、GPIO、Timer、Watchdog、MIL-STD-1553（関数レベル骨格付き） |
| Architecture rules | Cortex-M、Cortex-A、ESP32/Xtensa、RP2040、NRF52、RISC-V、PowerPC、SPARC V8 |
| RTOS guidance | FreeRTOS、Zephyr、RT-Thread：タスク設計、スレッドセーフ、ISR 連携、優先度逆転、デッドロック防止 |
| Build system | CMake クロスコンパイル、リンカスクリプト sections、スタートアップコード、コンパイラ属性 |
| Test & debug | HAL mock パターン、アサーションレベル、オンターゲットデバッグ規約 |
| Domains | Aerospace、military、industrial safety、automotive functional safety、general embedded |
| Anti-patterns | 5つの典型的アンチパターン（レジスタ散在、キャッシュコヒーレンシ、ISR ブロック、volatile 誤用、優先度逆転） |
| Review checklist | hardware sources、register access、concurrency、RTOS safety、behavior preservation、IDE-rule conflicts |
| Maintenance check | skill 変更後に generate、rewrite、review、RTOS、domain scenarios の smoke check を行う |

---

## コアルール

| 分類 | ルール |
|------|--------|
| 規則統一 | リポジトリコードが本スキルの規則に合致すればそのまま使用し、合致しなければ論理を変えずに規則に合わせて修正 |
| ハードウェア事実 | register offset、bit field、reset value、IRQ、barrier、timing を捏造しない |
| 出力形式 | generate、rewrite、review それぞれに IDE で扱いやすい形を使う |
| 型 | public interface では固定幅整数と `bool` を優先する |
| エラー処理 | プロジェクトに規約がない場合のみ `embedded_code_status_t` を使う |
| レジスタアクセス | 専用定義または既存の vendor/CMSIS 構造体を使う |
| メモリ | 低レベルドライバでは動的確保と VLA をデフォルトで避ける |
| 並行性 | ISR、DMA、cache、critical section、memory ordering は保守的に扱う |
| RTOS 安全 | ISR 内でブロック禁止、FromISR API 使用、共有データは同期プリミティブで保護 |

---

## 子領域のカバー範囲

`SKILL.md` には、次の子領域ルールを直接組み込んでいます。別ディレクトリには分けていません。

### Coding Standards

- 命名、pointer naming、固定幅型、`bool`
- fallback status type: `embedded_code_status_t`（`VALIDATE_NOT_NULL` と `VALIDATE_INIT` 付き）
- config struct、runtime handle、state enum の構成
- magic number、buffer size、timeout、retry count、コメント、review checklist

### Driver Templates

- 共通構成: `*_reg.h`、`*_reg_t`、`*_REG`、`MASK/SHIFT`
- **関数レベル骨格**: UART/SPI/GPIO/DMA の初期化、転送、ISR handler の完全パターン
- UART、SPI、I2C、DMA、CAN、GPIO、Timer、Watchdog、MIL-STD-1553 をカバー
- template は構成例であり、実際の offset、reserved bit、reset value、errata は対象資料に従う

### Architecture Rules

- ISR、barrier、DMA、cache、interrupt controller、SMP、memory ordering、CSR/SPR をカバー
- Cortex-M、Cortex-A、**ESP32/Xtensa**、**RP2040 デュアルコア**、**NRF52**、RISC-V、PowerPC、SPARC V8 の quick ref を含む
- ESP32 固有パターン: `IRAM_ATTR`、`FromISR` API、デュアルコア負荷分散、高レベル SPI API
- RP2040 固有パターン: Pico SDK、デュアルコア FIFO、DMA チャネル割り当て
- NRF52 固有パターン: nrfx ドライバ層、GPIOTE コールバック、SoftDevice 優先度
- 未知アーキテクチャでは資料を要求し、確認できない場合は architecture-neutral skeleton と placeholder に留める

### RTOS Guidance

- FreeRTOS、Zephyr、RT-Thread API 比較表
- タスク設計: スタックサイズ、優先度、作成順序、ウォッチドッグ
- スレッドセーフデータ共有: ミューテックス、キュー、アトミック操作
- ISR と RTOS の連携: ブロック禁止、FromISR API 使用、短く高速に
- 優先度逆転防止: 優先度継承ミューテックス
- デッドロック防止: 固定ロック順序、タイムアウト付き待機

### Build System

- リンカスクリプト: `.text`、`.rodata`、`.data` 再配置、`.bss` ゼロクリア
- スタートアップコード: データコピー、bss クリア、SystemInit、main 呼び出し順序
- コンパイラ属性: `interrupt`、`section`、`aligned`、`weak`、`always_inline`
- CMake クロスコンパイルテンプレート

### Test & Debug

- HAL mock パターン: 関数ポインタテーブルによる交換可能な HAL
- アサーションレベル: `STATIC_ASSERT`、`ASSERT`、`SOFT_ASSERT`
- オンターゲットデバッグ: デバッグピン、エラーコード追跡、スタックオーバーフロー検出、ウォッチドッグ、ログレベル

### Industry Domains

- Aerospace / DO-178C、Military / MIL-STD、Industrial / IEC 61508、Automotive / ISO 26262、General Embedded をカバー
- 各ドメインにデフォルト要件（動的割り当て禁止、safe state、インタフェース分離など）があるが、DAL/ASIL/SIL レーティングは汎用デフォルトとして扱わない

---

## IDE / Agent への調整

`SKILL.md` を唯一のソースとして、対象ツール向けにコアルールを取り出します。

次のパスは**対象リポジトリで生成する場所**です。このリポジトリに同梱されているファイルではありません。

- Cursor: `.cursor/rules/*.mdc`
- VS Code / Copilot: `.github/copilot-instructions.md`
- VS Code scoped instructions: `.github/instructions/*.instructions.md`
- Claude-compatible agents: `CLAUDE.md`
- Generic agents: `AGENTS.md`

対象リポジトリでは、重複を避けるため always-on の指示ファイルを基本的に 1 つにします。

---

## パッケージ構成

```text
embedded-code-skill/
├── SKILL.md       # 唯一のルール入口
├── install.sh     # インストールスクリプト
├── README.md      # 中国語 readme
├── README_EN.md   # 英語 readme
└── README_JP.md   # 日本語 readme
```

---

## ライセンス

MIT License
