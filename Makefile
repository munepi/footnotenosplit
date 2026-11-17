FNSVER := $(shell awk '/ProvidesPackage\{footnotenosplit\}/{getline; sub(/^ *\[/, ""); print $$2}' footnotenosplit.sty)

DOCS := footnotenosplit.pdf

LATEX_ENGINES  := pdflatex lualatex xelatex
TAGGED_ENGINES := pdflatex lualatex
PTEX_ENGINES   := platex uplatex

.PHONY: ctanzip
ctanzip: footnotenosplit.zip ## Archive for CTAN upload
footnotenosplit.zip: clean $(DOCS)
	git archive --format=tar --prefix=footnotenosplit/ HEAD | gtar -x
	## remove unpacked files
	cd footnotenosplit/ && \
		rm -f .gitignore Makefile ctan.toml
	## then, now just make archive
	zip -9 -r footnotenosplit.zip footnotenosplit/*
	rm -rf footnotenosplit
	@echo finished

.PHONY: footnotenosplit.pdf
footnotenosplit.pdf: footnotenosplit.tex
	pdflatex $<
	pdflatex $<

## Run the test suite ($(FNSVER)):
##  * every engine compiles its test files without footnotenosplit
##    warnings ("Failed to patch", etc.)
##  * the -show logs carry the patch traces
##    (fns@discard@emptyfootins / footnotetopkern)
##  * tagged PDF (\DocumentMetadata{tagging=on}, with and without
##    hyperref): the fntext/para hook carries the footnotenosplit chunk
.PHONY: test
test:
	@set -e; \
	for eng in $(LATEX_ENGINES); do \
	  for t in test-latex test-latex-show; do \
	    echo "== $$eng $$t"; \
	    $$eng -interaction=nonstopmode -jobname=$$t-$$eng $$t.tex >/dev/null; \
	    if grep -qi 'Failed to patch\|footnotenosplit Warning\|Incomplete \\if' $$t-$$eng.log; then \
	      echo "NG: footnotenosplit warning in $$t-$$eng.log"; exit 1; fi; \
	  done; \
	  grep -q 'fns@discard@emptyfootins' test-latex-show-$$eng.log || \
	    { echo "NG: no discard hook trace in test-latex-show-$$eng.log"; exit 1; }; \
	  grep -q 'footnotetopkern' test-latex-show-$$eng.log || \
	    { echo "NG: no splittopskip patch trace in test-latex-show-$$eng.log"; exit 1; }; \
	done; \
	for eng in $(TAGGED_ENGINES); do \
	  for v in tagged tagged-hy; do \
	    case $$v in tagged) pre='\def\TAGGING{1}';; \
	      tagged-hy) pre='\def\TAGGING{1}\def\HYPERREF{1}';; esac; \
	    for t in test-latex test-latex-show; do \
	      echo "== $$eng $$t ($$v)"; \
	      $$eng -interaction=nonstopmode -jobname=$$t-$$v-$$eng "$$pre\input $$t.tex" >/dev/null; \
	      if grep -qi 'Failed to patch\|footnotenosplit Warning\|Incomplete \\if' $$t-$$v-$$eng.log; then \
	        echo "NG: footnotenosplit warning in $$t-$$v-$$eng.log"; exit 1; fi; \
	    done; \
	    grep -q 'fns@discard@emptyfootins' test-latex-show-$$v-$$eng.log || \
	      { echo "NG: no discard hook trace in test-latex-show-$$v-$$eng.log"; exit 1; }; \
	    grep -q 'footnotenosplit -> \\splittopskip' test-latex-show-$$v-$$eng.log || \
	      { echo "NG: no fntext/para hook trace in test-latex-show-$$v-$$eng.log"; exit 1; }; \
	  done; \
	done; \
	for eng in $(PTEX_ENGINES); do \
	  for t in test-ptex test-ptex-show; do \
	    echo "== $$eng $$t"; \
	    $$eng -interaction=nonstopmode -jobname=$$t-$$eng $$t.tex >/dev/null; \
	    if grep -qi 'Failed to patch\|footnotenosplit Warning\|Incomplete \\if' $$t-$$eng.log; then \
	      echo "NG: footnotenosplit warning in $$t-$$eng.log"; exit 1; fi; \
	  done; \
	  dvipdfmx -q test-ptex-$$eng.dvi; \
	  grep -q 'fns@discard@emptyfootins' test-ptex-show-$$eng.log || \
	    { echo "NG: no @makecol patch trace in test-ptex-show-$$eng.log"; exit 1; }; \
	  grep -q 'footnotetopkern' test-ptex-show-$$eng.log || \
	    { echo "NG: no splittopskip patch trace in test-ptex-show-$$eng.log"; exit 1; }; \
	done; \
	echo "All tests passed ($(FNSVER))"

.PHONY: clean
clean: ## Clean this repository
	rm -rf footnotenosplit.zip footnotenosplit
	rm -f *.aux *.log *.out *.toc *.dvi *.synctex.gz
	rm -f *-pdflatex.* *-lualatex.* *-xelatex.* *-platex.* *-uplatex.*
	find . -type f -name "*~" -delete
