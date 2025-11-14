## Tooling for shell interactions 
Is it about finding FILES? use 'fd' 
Is it about finding TEXT/strings? use 'rg' 
Is it about finding CODE STRUCTURE? use 'ast-grep'
Is it about SELECTING from multiple results? pipe to 'fzf' 
Is it about interacting with JSON? use 'jq' 
Is it about interacting with YAML or XML? use 'yq'

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
