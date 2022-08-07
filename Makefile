.PHONY: all
all:
	make lint
	make test
	make format

.PHONY: test
test:
	nvim --headless --clean -c "lua require('test.config.bootstrap')" +qa!

.PHONY: lint
lint:
	luacheck lua

.PHONY: format
format:
	stylua lua
