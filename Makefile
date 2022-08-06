.PHONY: all
all:
	make lint
	make test

.PHONY: test
test:
	nvim --headless --clean -c "lua require('test.config.bootstrap')" +qa!

.PHONY: lint
lint:
	luacheck lua
