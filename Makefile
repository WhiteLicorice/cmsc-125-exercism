# Course fork of exercism/risc-v.
# This file has two targets. Do not add other targets.

EXERCISE ?=

.PHONY: test test-lab0

test:
	@bin/test-exercise "$(EXERCISE)"

test-lab0:
	@bin/score-lab0
