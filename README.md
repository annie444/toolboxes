# toolboxes

A containerized Linux development environment built on
[`fedora-toolbox`](https://containertoolbx.org/), packaged as an OCI image and
driven by a single launcher script: `box`.

The image bundles a full utility-development toolchain — `fish` shell, Neovim,
Rust (with cross-compilation targets), Go, Node 24, Python, Ruby, PHP, and a
long list of CLI tools — and the `box` script drops you into it with your host
config, SSH keys, GPG keys, and projects already wired in.

---

## Quick start

```sh
# from anywhere on your host
/path/to/toolboxes/box
```

That's it. The first run pulls `ghcr.io/annie444/linux-toolbox:latest`, creates
the backing volumes, and lands you in an interactive `fish` shell inside the
container — with your current directory as the working directory.

To make it ergonomic, put `box` on your `PATH`:

```sh
ln -s "$PWD/box" ~/.local/bin/box   # or anywhere on $PATH
box                                  # now usable from any directory
```

### Run a one-off command instead of a shell

Anything you pass to `box` is forwarded as the container's command:

```sh
box                     # interactive fish shell (default CMD)
box nvim README.md      # open Neovim on a host file
box cargo build         # build the project in $PWD
```

---

## What `box` does

`box` is a stateless launcher — it never builds anything. Each invocation runs a
**fresh, ephemeral container** (`--replace`, `--pull=newer`) against persistent
storage, so the container itself is disposable while your data survives.

On every run it:

1. **Picks a runtime** — prefers `podman`, falls back to `docker`.
2. **Detects your architecture** — maps `arm64`/`amd64` to the right
   `linux/*` platform.
3. **Ensures named volumes exist** for machine-generated caches and state
   (cargo registry, cargo target, Go path, npm cache, the XDG `~/.local/*`
   tree, `~/.cache`). These are _not_ on your host filesystem.
4. **Bind-mounts your host config and code** so the container feels like your
   real environment: `~/.config/*` (fish, git, gh, nvim, starship, atuin, ...),
   `~/.ssh`, `~/.gnupg`, `~/.dotfiles`, `~/Projects`, and more.
5. **Forwards your environment** — every host env var is passed through
   _except_ a denylist of vars that would break paths inside the container
   (`PATH`, `HOME`, `XDG_*`, etc.), so API keys and project vars "just work."
6. **Runs interactively** with a TTY, `--network=host`, hostname set to the
   image name, and `--workdir=$PWD`.

> [!NOTE]
> The container runs as `root` _inside_ the namespace, and mounts your real
> `~/.ssh`, `~/.gnupg`, and `~/Projects`. Treat it as you would your own
> account — it has the same access you do.

---

## Configuration

`box` is configured entirely through environment variables. Defaults shown:

| Variable               | Default           | Purpose                                             |
| ---------------------- | ----------------- | --------------------------------------------------- |
| `CONTAINER_REGISTRY`   | `ghcr.io`         | Image registry                                      |
| `CONTAINER_NS`         | `annie444`        | Registry namespace / owner                          |
| `CONTAINER_TAG`        | `latest`          | Image tag                                           |
| `CONTAINER_PREFIX`     | `linux`           | Name prefix (`<prefix><suffix>` → image name)       |
| `CONTAINER_SUFFIX`     | `-toolbox`        | Name suffix                                         |
| `CONTAINER_NAME`       | `linux-toolbox`   | Full image/container name (overrides prefix+suffix) |
| `CONTAINER_PLATFORM`   | auto-detected     | e.g. `linux/arm64`, `linux/amd64`                   |
| `CONTAINER_EXECUTABLE` | `podman`/`docker` | Force a specific runtime                            |
| `DEBUG`                | _unset_           | Set to any value to `set -x` and trace the script   |

Examples:

```sh
# pin a specific tag
CONTAINER_TAG=v1.2.3 box

# force docker even if podman is installed
CONTAINER_EXECUTABLE=docker box

# run the amd64 image on an arm64 host (emulation)
CONTAINER_PLATFORM=linux/amd64 box

# see exactly what command gets run
DEBUG=1 box
```

Volume names are namespaced by `<name>-<arch>-*` (e.g.
`linux-toolbox-arm64-cargo-registry`), so arm64 and amd64 runs keep separate
caches and never collide.

---

## Building the image locally

You don't need to build anything to use `box` — it pulls from the registry. But
if you want to build the image yourself, use the [`just`](https://just.systems/)
recipe:

```sh
just build
```

This builds `Containerfile.linux` for your current platform, tagging it
`ghcr.io/annie444/linux-toolbox:latest` with the appropriate toolbox labels and
OCI annotations. Override the same `CONTAINER_*` / `FEDORA_VERSION` variables to
change the target.

---

## Repository layout

| Path                        | Description                                                  |
| --------------------------- | ------------------------------------------------------------ |
| `box`                       | The launcher script (the main entry point)                   |
| `Containerfile.linux`       | Image definition — Fedora toolbox + full toolchain           |
| `Justfile`                  | `just build` recipe for building the image                   |
| `linux/pkgs-*.txt`          | Per-architecture DNF package lists installed into the image  |
| `bin/colorscript`           | `colorscript` CLI (shipped to `/usr/local/bin` in the image) |
| `share/shell-color-scripts` | Terminal color-script collection shown in the shell          |

---

## What's in the image

A non-exhaustive tour of what the toolbox ships with:

- **Shell & TUI:** `fish`, `starship`, `atuin`, `tmux`, `zoxide`, `fzf`,
  `eza`, `bat`, `fd`, `ripgrep`, `btop`, `htop`, `lazygit`, `delta`
- **Editors:** Neovim (with Python/Ruby/Node/Perl providers preconfigured and
  OSC 52 clipboard support)
- **Languages & build:** Rust (+ wasm and Windows/Linux cross targets via
  `cargo-xwin`/`mingw`/`wine`), Go, Node 24 + `pnpm`, Python + `uv`, Ruby, PHP +
  Composer, `cmake`, `meson`, `ninja`, `clang`/`llvm`, `gdb`, `valgrind`
- **Dev tooling:** `git`, `gh`, GitHub Copilot CLI, Claude Code, `direnv`,
  `jq`, `shellcheck`, `tree-sitter-cli`
- **Networking & system:** `curl`, `wget2`, `rsync`, `openssh`, `mtr`,
  `tcpdump`, `iftop`, `traceroute`

See `linux/pkgs-x86_64.txt` / `linux/pkgs-aarch64.txt` for the complete list.
