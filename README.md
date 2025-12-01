# HOME

The repo hold all the usefull staff I keep in `~/` ($HOME)

- .config/nvim - nvim config
- .config/wezterm - wezterm config
- .zshrc - my zsh

### nvim

nvim is configured mostly for Go, there are basic plugins + lazyvim + a few my actions like json to go or json string escaper

#### plan to rewrite config

##### polish basics

- keymaps[+]
- autocommand[+]
- options[+]

##### first plugins

- theme[+]
- hipatterns[+]
- which key[+]

##### minimum functional

- treesitter[+]
- session[+]
- mason installer[+]
- lsp[+]
- diagnostic[+]
- fzf[+]
- neotree[+]
- cmp[+]
- neotest[+]
- dap[+]
- conform[+]
- pairs[+]
- lint[+]

##### nice to have

- illuminate[+]
- diffview[-]
- gitsigns[+]
- bufferline[+]
- blame[-]
- yazi/oil[-]
- replace[+]
- go[+]
- leap[+]
- surround[-]
- trouble[-]
- toggle term[-]
- mini ai[-]
- treesitter text objects[+]
- treesitter context[+]
- nvim-notify[+]


##### consider if useful 

- helm
- luasnip
- matchup
- todo[-]
- neoscroll
- indent
- lualine[-]
- comment[-]
- md
- project[-]
- refactoring[-]
- schema (schema store)[-]
- ts
- bufdel[-]
- dim[-]


##### to read

- build compile command: https://phelipetls.github.io/posts/async-make-in-nvim-with-lua/
- run coroutines: https://gregorias.github.io/posts/using-coroutines-in-neovim-lua/

### wezterm

just fonts, macos compatible movement keys and color theme

### zshrc

power10k + power10k prompt config and a couple clis like bat, eza, fzf

#### how to use

Everything uncommented must be interpreted as is, the rest info might be given from the comments and there are no many of them.
Feel free to use, not very fancy.


### Claude 

My basic skills and agents setup.

#### lsp mcps to consider 

        "zls": {
          "type": "stdio",
          "command": "mcp-language-server",
          "args": [
            "--workspace",
            "project dir",
            "--lsp",
            "zls"
          ],
          "env": {}
        },
        "cclsp": {
          "type": "stdio",
          "command": "npx",
          "args": [
            "cclsp@latest"
          ],
          "env": {
            "CCLSP_CONFIG_PATH": "path to cclsp.json"
          }
        },
// -- cclsp.json example ---
{
    "servers": [
        {
            "extensions": [
                "zig"
            ],
            "command": [
                "zls"
            ],
            "rootDir": "."
        }
    ]
}

