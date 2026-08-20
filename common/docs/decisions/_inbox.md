# decisions inbox — __PROJECT_TITLE__

まだ判断ルールに昇格していない観測ログ。**捨てる前提の粗い記録**。

- 書き込むのは AI（`.ai/prompts/handoff.md` 経由）。人間は原則書かない
- 1回目で無条件に記録する。重複排除はここではやらない
- 昇格判定は `make promote` が機械的に行う

## 形式

```
- YYYY-MM-DD | __PROJECT_SLUG__ | keyword | 種別 | 内容
```

種別: `ask`（AIが確認を求めた） / `redo`（差し戻された） / `oral`（口頭で伝えた前提）

区切りは半角スペース + パイプ + 半角スペース。内容にパイプを含めない。
この形式に一致しない行は集計時に無視されるので、メモを書き足しても壊れない。

## 昇格ルート

| 条件 | 昇格先 |
|---|---|
| 同一 keyword が同一案件で2回以上 | `docs/decisions/NNNN-*.md`（案件固有の決定） |
| 同一 keyword が**2案件以上**で出現 | テンプレートの `common/.cursor/rules/10-conventions.mdc`<br>（スタック固有なら `stacks/<id>/.cursor/rules/`） |

昇格したら `make promoted KW=<keyword> NOTE=<昇格先>` を実行する。
以後その keyword は `make promote` の候補から除外される（行は消さなくてよい）。
**テンプレート側に戻すまでが1セット**。案件側だけ直すと次の案件で再発する。

## keyword 一覧

AI が新規 keyword を作ったらここに追記される。
**新規作成前に必ずこの一覧を確認し、意味が通るなら既存を再利用すること。**

<!-- keywords:start -->
<!-- keywords:end -->

## 昇格済み

<!-- promoted:start -->
<!-- promoted:end -->

---

## ログ

<!-- entries:start -->
<!-- entries:end -->
