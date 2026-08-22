


# Restrictions

- File editing must be done via the editor API. Editing using terminal commands such as `cat >` is prohibited because it will not be recorded in the editor's change history or updated file list.
- Without pandering to users or providing answers they desire, we consistently provide calm, honest answers and work based on science, facts, and the latest information, determined by deep insight.



# Index

- Read each document only when necessary.
- Whenever you create a new document, be sure to add it here.
- You do not need to add Japanese documentation.
- You do not need to make any changes to AGENTS.md other than adding or removing documentation.



## PRINCIPLES (Documents, Developments, Condig, Tests)

[PRINCIPLES.md](.docs/PRINCIPLES.md)

## All DECISIONS for this repository

[DECISIONS.yml](DECISIONS.yml)

## records history for this repository

[records/](records/)



<!-- BEGIN MYDEVSETUP DEV TOOLS -->
## Installed development tools
- `ruby`: `ruby`
- `ripgrep`: `rg` - Fast Rust line-oriented recursive regex search; respects .gitignore and skips hidden/binary files by default. Use rg -uuu to disable filtering.
- `rtk`: `rtk` - High-performance output-filtering/compression proxy for LLM context. Use rtk --help; useful subcommands include ls, tree, read, git, psql, pnpm, json, env, find, diff, log, grep, and npx.
- `codegraph`: `codegraph` - Maps code to tests, breakage, affected flows, and business-logic risk.
- `uv`: `uv`
- `serena`: `serena`
- `python`: `python3`
- `node`: `node`
<!-- END MYDEVSETUP DEV TOOLS -->
