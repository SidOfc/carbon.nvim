.PHONY: all
all:
	make lint
	make format-check
	make test

.PHONY: test
test:
	nvim --headless --clean -c "lua require('test.config.bootstrap')" +qa!

.PHONY: lint
lint:
	@make lint-luacheck
	@make lint-luals

.PHONY: lint-luacheck
lint-luacheck:
	luacheck lua

.PHONY: lint-luals
lint-luals:
	lua-language-server --check .

.PHONY: format-check
format-check:
	stylua lua --check

.PHONY: dev
dev:
	nvim -Nu dev/init.lua
