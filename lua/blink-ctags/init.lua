--- @class blink.cmp.Source
local Source = {}

function Source.new()
	return setmetatable({}, { __index = Source })
end

-- C,constant
-- a,augroup
-- c,command
-- f,function
-- k,class
-- m,map
-- n,filename
-- v,variable

local kind_map = {
	C = vim.lsp.protocol.CompletionItemKind.Constant,
	f = vim.lsp.protocol.CompletionItemKind.Function,
	k = vim.lsp.protocol.CompletionItemKind.Class,
	m = vim.lsp.protocol.CompletionItemKind.Method,
	n = vim.lsp.protocol.CompletionItemKind.File,
	v = vim.lsp.protocol.CompletionItemKind.Variable,
}

function Source:get_completions(ctx, callback)
	local filename_origin = vim.fn.expand("%:p")

	local cmd = {
		"nvim",
		"--headless",
		"+set tagcase=match",
		string.format(
			[[+lua print(vim.json.encode(vim.fn.taglist("^%s", "%s")))]],
			vim.fn.escape(ctx:get_keyword(), '"'),
			vim.fn.escape(filename_origin, '"')
		),
		"+q",
	}

	local process = vim.system(
		cmd,
		{ text = true },
		vim.schedule_wrap(function(out)
			if out.signal ~= 0 then
				return
			end

			local tags = vim.json.decode(out.stderr or "[]")

			--- @type lsp.CompletionItem[]
			local items = {}

			for _, v in ipairs(tags) do
				if #items == 100 then
					break
				end

				if vim.fn.fnamemodify(v.filename, ":e") == vim.fn.fnamemodify(filename_origin, ":e") then
					table.insert(items, {
						label = v.name,
						detail = vim.trim(v.cmd:sub(3, -3)),
						kind = kind_map[v.kind],
						labelDetails = {
							description = vim.fn.fnamemodify(v.filename, ":t"),
						},
					})
				end
			end

			callback({ items = items, is_incomplete_backward = true, is_incomplete_forward = false })
		end)
	)

	return function()
		process:kill(9)
	end
end

return Source
