# Tools Cheat Sheet (fzf, rg, ast-grep)

## fzf

- Find files: `fzf`
- Case insensitive: `fzf -i`
- Case sensitive: `fzf +i`
- Border: `fzf --border sharp`
- From dir: `find dir -type f | fzf`
- Save selection: `find . -type f "*.txt" | fzf --multi > out.txt`
- From processes: `ps aux | fzf`
- Multi-select: `find dir -type f | fzf --multi > file`
- With query: `fzf --query "query"`
- Regex query: `fzf --query "^core go$ | rb$ | py$"`
- Negated query: `fzf --query "!pyc 'travis"`

## ripgrep (rg)

- Glob: `rg 'pattern' -g '*.ext'`
- Type: `rg 'pattern' --type rust` or `--trust`
- Exclude type: `--type-not markdown`
- Case insensitive: `-i`
- Regex: `rg 'fast\w+' file`
- Literal: `rg -F 'hello.*'`
- Context: `-B 1`, `-A 1`, `-C 1`
- Stats: `--stats`
- Exclude dir: `-g '!dir/'`
- Find files: `rg --files | rg keyword`

## ast-grep (sg)

- Replace print in Python: `sg -l py -p 'print($A)' -r 'logging.info($A)'`
- Remove TS `useState<number>`: `sg -p 'useState<number>($A)' -r 'useState($A)'`
- Swap Yew `use_memo`: `sg -l rs -p 'use_memo($D,,$$$C)' -r 'use_memo($D,$$$C)'`
- Refactor TS:
  ```sh
  ast-grep -p '$PROP && $PROP()' \
           -r '$PROP?.()' \
           -l ts --interactive \
           TypeScript/src
  ```
