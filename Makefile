.DEFAULT_GOAL = test

.PHONY: test
test:
	bash ./test $(test)

.PHONY: testcov
testcov:
	TEST_COV=1 $(MAKE) --no-print-directory test
	@luacov-console lua/microscope/
	@luacov-console -s
	@luacov

.PHONY: testcov-html
testcov-html:
	NOCLEAN=1 $(MAKE) --no-print-directory testcov
	luacov -r html
	xdg-open luacov-html/index.html
