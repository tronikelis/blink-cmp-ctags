--- @class blink-ctags.Source.Opts
--- @field max_items integer?
--- @field kind_map table<string, integer>?
--- @field prefix_search boolean?
--- @field match_filename boolean?
--- @field tagcase string?

--- @class blink-ctags.Source
--- @field opts blink-ctags.Source.Opts
local Source = {
	opts = {
		max_items = nil,
		kind_map = {
			-- C,constant
			-- a,augroup
			-- c,command
			-- f,function
			-- k,class
			-- m,map
			-- n,filename
			-- v,variable
			C = vim.lsp.protocol.CompletionItemKind.Constant,
			f = vim.lsp.protocol.CompletionItemKind.Function,
			k = vim.lsp.protocol.CompletionItemKind.Class,
			c = vim.lsp.protocol.CompletionItemKind.Class,
			m = vim.lsp.protocol.CompletionItemKind.Method,
			n = vim.lsp.protocol.CompletionItemKind.File,
			v = vim.lsp.protocol.CompletionItemKind.Variable,
		},
		prefix_search = true,
		match_filename = true,
		tagcase = "ignore",
	},
}

function Source.new(opts)
	opts = opts or {}
	opts = vim.tbl_deep_extend("force", Source.opts, opts)
	return setmetatable({ opts = opts }, { __index = Source })
end

---@return string
function Source:get_prefix_search()
	if self.opts.prefix_search then
		return "^"
	end
	return ""
end

function Source:get_completions(ctx, callback)
	if vim.bo.buftype ~= "" or #vim.fn.tagfiles() == 0 then
		callback()
		return
	end

	local filename_origin = vim.fn.expand("%:p")
	local prefix_search = self:get_prefix_search()

	local cmd = {
		"nvim",
		"--clean",
		"--headless",
		string.format("+sandbox set tagcase=%s", self.opts.tagcase),
		string.format("+sandbox set tags=%s", vim.api.nvim_get_option_value("tags", {})),
		string.format(
			[[+lua io.write(vim.mpack.encode(vim.fn.taglist("%s%s", "%s")))]],
			prefix_search,
			vim.fn.escape(ctx:get_keyword(), '"$' .. prefix_search),
			vim.fn.escape(filename_origin, '"')
		),
		"+q",
	}

	local process = vim.system(
		cmd,
		{ text = false },
		vim.schedule_wrap(function(out)
			if out.signal ~= 0 then
				callback()
				return
			end

			local tags = vim.mpack.decode(out.stdout or "[]")

			---@type lsp.CompletionItem[]
			local items = {}

			for _, v in ipairs(tags) do
				if self.opts.max_items and #items == self.opts.max_items then
					break
				end

				---@type lsp.CompletionItem
				local item = {
					label = v.name,
					detail = vim.trim(v.cmd:sub(3, -3)),
					kind = self.opts.kind_map[v.kind],
					labelDetails = {
						description = vim.fn.fnamemodify(v.filename, ":t"),
					},
				}

				if self.opts.match_filename then
					if vim.fn.fnamemodify(v.filename, ":e") == vim.fn.fnamemodify(filename_origin, ":e") then
						table.insert(items, item)
					end
				else
					table.insert(items, item)
				end
			end

			callback({
				items = items,
				is_incomplete_backward = true,
				is_incomplete_forward = false,
			})
		end)
	)

	return function()
		process:kill(9)
	end
end

return Source
