VIMRUNTIME = $(shell nvim --headless --cmd 'lua io.write(vim.env.VIMRUNTIME)' --cmd 'qa')

.PHONY: all
all:
	make lint
	make format-check
	make test

.PHONY: test
test:
	@echo "test(PLENARY):"
	@nvim --headless --clean -c "lua require('test.config.bootstrap')" +qa

.PHONY: lint
lint:
	@make lint-luacheck
	@make lint-luals

.PHONY: lint-luacheck
lint-luacheck:
	@echo "lint(LUACHECK):"
	@luacheck lua

.PHONY: lint-luals
lint-luals:
	@echo "lint(LUALS):"
	@VIMRUNTIME=$(VIMRUNTIME) lua-language-server --check .

.PHONY: format-check
format-check:
	@echo "format(STYLUA):"
	@stylua lua --check

.PHONY: dev
dev:
	nvim -Nu dev/init.lua
