# Tools Cheat Sheet (fzf, rg, ast-grep)

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
