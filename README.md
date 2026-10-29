# AI Agents Auto-Build Docker Image

Daily-built, multi-arch Docker images with popular AI coding agents and Kubernetes/Tekton debugging tools pre-installed. Available on Ubuntu, Red Hat UBI 9 and Alpine.

## Included Tools

**AI coding agents**

| Command | Tool | Installed from |
|---------|------|----------------|
| `claude` | [Claude Code](https://github.com/anthropics/claude-code) | Official install script |
| `codex` | [OpenAI Codex CLI](https://github.com/openai/codex) | npm `@openai/codex` |
| `agy` | [Antigravity CLI](https://antigravity.google/) (Google's successor to Gemini CLI) | Official install script |
| `gemini` | [Gemini CLI](https://github.com/google-gemini/gemini-cli) | npm `@google/gemini-cli` |
| `copilot` | [GitHub Copilot CLI](https://github.com/github/copilot-cli) | npm `@github/copilot` |
| `opencode` | [OpenCode](https://github.com/anomalyco/opencode) | GitHub release |
| `pi` | [Pi coding agent](https://github.com/earendil-works/pi) | npm `@earendil-works/pi-coding-agent` |
| `paco` | [Paco](https://github.com/pipelines-as-code/paco-cli) AI code reviewer | GitHub release |

**Developer and cluster tools:** Node.js 24 (with npm/npx; on Alpine, the version Alpine packages), `git`, `gh`, `glab`, `kubectl`, `stern`, `yq`, `jq`, `ripgrep` (`rg`), `fd`, `ast-grep` (`sg`), `shellcheck`, `make`, `curl`.

All tools track their latest release: every build installs the newest version.

## Current Versions

<!-- versions-start -->
| Tool | Version |
|------|---------|
| node | 24.22.2 |
| codex | codex-cli 0.165.0 |
| claude | 2.1.312 (Claude Code) |
| gemini | 0.66.0 |
| agy | 1.4.10 |
| opencode | 1.19.5 |
| copilot | GitHub Copilot CLI 1.0.105. |
| pi | 1.4.0 |
| sg | ast-grep 0.51.0 |
| yq | yq (https://github.com/mikefarah/yq/) version v4.54.1 |
| gh | gh version 2.103.3 (2026-10-26) |
| glab | glab 1.126.0 (4dd0d32d1) |
| kubectl | Client Version: v1.37.2 |
| stern | version: 1.35.0 |
| rg | ripgrep 15.2.0 |
| fd | fdfind 10.4.2 |
| jq | jq-1.8.2 |
| shellcheck | 0.11.0 |

_Last updated: 2026-10-29T18:04:12Z_
<!-- versions-end -->

Versions are from the Ubuntu image and are updated automatically after each published build.

## Image Variants

| Tag | Base | Package manager | Notes |
|-----|------|-----------------|-------|
| `:latest`, `:ubuntu` | Ubuntu (rolling) | `apt-get` | General-purpose default |
| `:latest-ubi`, `:ubi` | [Red Hat UBI 9](https://catalog.redhat.com/software/base-images) | `dnf` | RHEL-compatible, for OpenShift / enterprise environments |
| `:latest-alpine`, `:alpine` | Alpine Linux | `apk` | musl-based; Node.js comes from Alpine packages |

Each build is also tagged with its commit, e.g. `:main-<sha>`, `:main-<sha>-ubi`, `:main-<sha>-alpine`.

All variants are built for:

- `linux/amd64` (x86_64)
- `linux/arm64` (including Apple Silicon Macs, running natively)

## Usage

### Pull

```bash
docker pull ghcr.io/nqbao/agents-image:latest
```

If the pull is denied, the package may be private: log in with `docker login ghcr.io` using a GitHub token with `read:packages`.

### Run

```bash
# Interactive shell
docker run -it --rm ghcr.io/nqbao/agents-image:latest

# Run a specific tool
docker run -it --rm ghcr.io/nqbao/agents-image:latest claude --help
docker run -it --rm ghcr.io/nqbao/agents-image:latest codex --help
docker run -it --rm ghcr.io/nqbao/agents-image:latest agy --help
```

### Work on a local project

```bash
docker run -it --rm \
  -v "$(pwd)":/workspace -w /workspace \
  ghcr.io/nqbao/agents-image:latest
```

The container runs as `aiuser` (UID/GID 1000), so files it creates in the mounted directory are owned by UID 1000 on the host.

### Keep logins and settings between runs

Agent credentials and config live in the home directory, `/user`. Mount a volume there to persist them:

```bash
docker run -it --rm \
  -v agents-home:/user \
  -v "$(pwd)":/workspace -w /workspace \
  ghcr.io/nqbao/agents-image:latest
```

Tools themselves are installed under `/usr/local`, so mounting `/user` never hides or replaces them.

### Install additional npm packages

The pre-installed tools are owned by root, so install extra global packages into your home directory instead (`/user/.local/bin` is already on `PATH`):

```bash
npm install -g --prefix ~/.local <package-name>
```

Or run a package without installing it: `npx <package-name>`.

## User Configuration

- **Username**: `aiuser`
- **UID/GID**: 1000:1000
- **Home directory**: `/user`
- **Shell**: `/bin/bash`

There is no `sudo`; tools can't self-update inside the container. Pull a newer image instead.

## Build Locally

```bash
make ubuntu   # docker build -t agents-image .
make ubi      # docker build -f Dockerfile.ubi -t agents-image:ubi .
make alpine   # docker build -f Dockerfile.alpine -t agents-image:alpine .
make all      # all three
```

Multi-architecture builds (requires `docker buildx`):

```bash
make buildx-all   # or buildx-ubuntu / buildx-ubi / buildx-alpine
```

## Automated Builds

Builds run in GitHub Actions (`.github/workflows/build-docker.yml`) and push to `ghcr.io/nqbao/agents-image`:

- **Daily** at 02:00 UTC on `main`: builds and publishes all variants, then updates the versions table above.
- **Manual** via workflow dispatch, using the helper script (requires an authenticated `gh` CLI):

```bash
./run-and-tail-workflow.sh      # run on the current branch and follow the logs
./run-and-tail-workflow.sh -n   # build only, don't publish (even on main)
```

Images are only published from `main`. Runs on other branches just test the build, which is how to check a change before merging. Pull requests and pushes don't trigger builds.

## License

[Apache License 2.0](./LICENSE)
