# footnotenosplit Package

**LaTeX: Suppress orphan footnote rules when footnotes are not allowed to split**

Setting `\interfootnotelinepenalty=10000` keeps footnote text from being split across pages: a footnote that does not fit on the current page is moved to the next page as a whole. This policy is common in book production, but it has two side effects:

1. The original page may end with a **lone `\footnoterule`** (plus the `\skip\footins` space) with no footnote text below it.
2. The footnote moved to the next page gets only `\splittopskip` (= `\footnotesep`) above its first line, so it sits closer to the rule than a normal footnote does.

This happens with any engine — it is a property of TeX's page builder and the LaTeX output routine, not of a particular language or engine. It shows up when the footnote insertion begins with vertical material such as a leading `\kern` in `\@makefntext` (common in book-production classes) and the page bottom has stretch (`\raggedbottom`).

The footnotenosplit package suppresses both side effects:

1. If `\ht\footins < \footnotesep` (the footnote box holds no actual footnote line), the box is discarded, so neither `\footnoterule` nor `\skip\footins` is emitted. The footnote itself is typeset normally on the next page.
2. `\splittopskip` inside `\@footnotetext` (or `\H@@footnotetext` when hyperref is loaded) is patched to `\footnotesep + \footnotetopkern`. In tagged PDF documents (`\DocumentMetadata{tagging=on}`), where the kernel's tagging code replaces `\@footnotetext`, the same value is set in the `fntext/para` hook instead.

* **Supported formats/engines:** pdfLaTeX, LuaLaTeX, XeLaTeX (LaTeX2e 2025-06-01 or later), pLaTeX, upLaTeX
* **Tagged PDF:** works with `\DocumentMetadata{tagging=on}` (pdfLaTeX, LuaLaTeX)

## Files

| File | Description |
|---|---|
| `footnotenosplit.sty` | The package: options, the `\splittopskip` patch, and engine dispatch |
| `footnotenosplit-ptex.sty` | Implementation for (u)pLaTeX (patches the `\@makecol` of plcore.ltx) |
| `footnotenosplit-latex.sty` | Implementation for the socket-based LaTeX kernel (uses the `build/column/before` hook) |

The implementation files are loaded automatically; do not load them directly.

## Requirements

* LaTeX2e 2025-06-01 or later (for pdfLaTeX/LuaLaTeX/XeLaTeX; the socket-based `\@makecol`), or pLaTeX2e for (u)pLaTeX
* `etoolbox`

## Installation

Copy the three `.sty` files to your local TeX tree:
`$TEXMF/tex/latex/footnotenosplit/`

## Usage

```latex
\usepackage{footnotenosplit}

% If your class's \@makefntext starts with "\kern <dimen>",
% set \footnotetopkern to that dimension and replace the \kern:
\footnotetopkern=2pt
\makeatletter
\renewcommand\@makefntext[1]{\kern\footnotetopkern ... #1}
\makeatother
```

By default the package sets `\interfootnotelinepenalty=\@M` for you. If your class already sets it (or you want to manage it yourself), load the package with the `nopenalty` option:

```latex
\usepackage[nopenalty]{footnotenosplit}
```

## Testing

The repository ships four test files:

* `test-latex.tex` (pdfLaTeX/LuaLaTeX/XeLaTeX) and `test-ptex.tex` ((u)pLaTeX + dvipdfmx) reproduce the orphan footnote rule and verify that the package suppresses it. Build a control version without the package via `"\def\NOPKG{1}\input test-latex.tex"` and compare the page where the long footnote reference sits at the very bottom. The filler-line count `\FILLN` may need rescanning on TeX distributions other than TeX Live 2026.
* `test-latex-show.tex` / `test-ptex-show.tex` dump the patched macros to the log for a quick patch-status check (`make test` greps these).
* The pdfLaTeX/LuaLaTeX tests also run as tagged PDF via `"\def\TAGGING{1}\input test-latex.tex"` (add `\def\HYPERREF{1}` for hyperref); `make test` covers these variants.

## Repository

* <https://github.com/munepi/footnotenosplit>
* Bug reports: <https://github.com/munepi/footnotenosplit/issues>

## License

This package is licensed under the conditions of the [LaTeX Project Public License](https://www.latex-project.org/lppl.txt), either version 1.3c of this license or any later version.

Copyright (c) 2026 Munehiro Yamamoto
