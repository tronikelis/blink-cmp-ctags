# blink-cmp-ctags

Async blink.cmp source for (c)tags

[![asciicast](https://asciinema.org/a/WpNC9NLyMQ4jUbydhlWK4dmYP.svg)](https://asciinema.org/a/WpNC9NLyMQ4jUbydhlWK4dmYP)

## Quick start

Generate ctags for your project with `ctags -R --sort=foldcase`
foldcase is recommended for binary search support if ignoring case,
which is done by default.

Enable the source. 
Example configuration:

```lua
sources = {
    default = {
        "lsp",
        "buffer",
        "ctags",
    },
    providers = {
        lsp = { fallbacks = { "buffer", "ctags" } },
        ctags = {
            name = "Ctags",
            module = "blink-ctags",
            -- put ctags below buffer
            score_offset = -10,
            min_keyword_length = 4,
            -- custom opts
            opts = {}
        },
    },
},
```

## Opts

```lua
opts = {
    -- usually you shouldn't notice any performance, 
    -- but for huge tags files you can try lowering the max_items
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
    -- should the keyword match at the start of the identifier?
    -- enable to support binary search for tags
    prefix_search = true,
    -- show tags for the current file extension only
    match_filename = true,
    tagcase = "ignore",
},
```



