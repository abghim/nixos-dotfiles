# muljil

TPM-manageable tmux plugin packaging the project picker, add-project popup, remove-project popup, and the tmux config that originally lived in `tmux-add.conf`.

TPM expects the contents of this directory to be the plugin repository root. In other words, publish `muljil/` as its own repo, or copy/symlink this directory into `~/.tmux/plugins/muljil`.

## Install

Add this to your tmux config:

```tmux
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'muljil/muljil'

run '~/.tmux/plugins/tpm/tpm'
```

If you also want the original resurrect/continuum behavior, keep their plugin lines in your tmux config as well. TPM cannot reliably install nested plugin dependencies declared from inside another plugin.

## Behavior

This plugin applies the settings from the packaged tmux config, including:

- `C-q` as the prefix
- top status bar theme and pane/window styling
- mouse bindings
- popup bindings:
  - `a` opens the project picker
  - `A` adds a project
  - `R` removes a project
  - `b` switches to the `main` session

## Data File

Projects are stored in `~/.config/muljil/projects.tsv` by default.

Override that path with:

```tmux
set -g @muljil-projects-file '~/.local/share/muljil/projects.tsv'
```

## Dependencies

- `tmux`
- `gum`
- `awk`
