.PHONY: test
test:
	nvim --headless --noplugin -c "lua require('test.config.bootstrap')" +qa!

.PHONY: lint
lint:
	luacheck lua
