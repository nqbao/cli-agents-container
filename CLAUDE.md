# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Automated daily-built Docker images (Ubuntu rolling and UBI 9) with six AI coding assistants and Kubernetes/Tekton debugging tools pre-installed:
- `@openai/codex`, `@google/gemini-cli`, and `@earendil-works/pi-coding-agent` (`pi`) — installed via npm globally
- `claude` — installed via official `https://claude.ai/install.sh` script
- `agy` (Antigravity CLI, successor to Gemini CLI) — installed via official `https://antigravity.google/cli/install.sh` script
- `opencode` — installed from GitHub release binary (anomalyco/opencode)
- `kubectl`, `stern` — Kubernetes CLI tools for cluster debugging

Published to `ghcr.io/chmouel/agents-image` (`:latest` for Ubuntu, `:latest-ubi` for UBI 9) via GitHub Actions.

## Architecture

Two Dockerfiles share the same multi-stage structure (`builder` + runtime):

- **`Dockerfile`** (Ubuntu rolling): uses `apt-get` for system packages; ripgrep, fd-find, and shellcheck come from Ubuntu repos
- **`Dockerfile.ubi`** (UBI 9): uses `dnf` for system packages; ripgrep, fd, and shellcheck are downloaded from GitHub releases since they are not in UBI repos

Both install Node.js 24.22.2 from official binary tarballs to handle `linux/amd64` and `linux/arm64` via `TARGETARCH`. All other tools (ast-grep, yq, glab, kubectl, stern, opencode) are fetched from GitHub/GitLab releases identically in both variants.

## User Configuration

- **User**: `aiuser` (UID/GID 1000:1000)
- **Home directory**: `/user` (not `/home/aiuser`)
- **Shell**: `/bin/bash`
- **Notes**: The `ubuntu` user is removed from the Ubuntu base image to avoid conflicts (not needed for UBI). UID/GID 1000 ensures predictable file permissions when mounting volumes.

## Key Build Commands

```bash
# Local single-arch build (Ubuntu)
docker build -t agents-image .

# Local single-arch build (UBI 9)
docker build -f Dockerfile.ubi -t agents-image:ubi .

# Local multi-arch build (requires buildx)
docker buildx build --platform linux/amd64,linux/arm64 -t agents-image .
docker buildx build --platform linux/amd64,linux/arm64 -f Dockerfile.ubi -t agents-image:ubi .
```

## Triggering and Monitoring the CI Workflow

Use the helper script (requires `gh` CLI authenticated):

```bash
# Trigger and tail the workflow
./run-and-tail-workflow.sh

# Trigger with debug mode enabled
./run-and-tail-workflow.sh -d
```

The script triggers `.github/workflows/build-docker.yml` on the current branch, waits for the run to appear, then watches it with `gh run watch`. On failure it dumps logs automatically. Images are pushed and `version.json` updated only for runs on the default branch; runs on other branches just test the build.

## Version Pinning

- Node.js version is hardcoded in both `Dockerfile` and `Dockerfile.ubi` (`NODE_VERSION="24.22.2"`) in **both** the builder and runtime stages — update all four locations when bumping. Pi requires Node >= 22.19.
- GitHub-release tools (OpenCode, ast-grep, yq, stern, paco, and on UBI ripgrep/fd/shellcheck) resolve their latest tag via the `https://github.com/<repo>/releases/latest` redirect rather than the GitHub API, to avoid the unauthenticated API rate limit on CI runners — no versions to maintain.
- All tool installs (npm, claude and agy install.sh, GitHub release downloads) are cache-busted on every CI run via `ARG CACHEBUST` (set to `github.run_id` in the workflow), while the Node.js download layer remains cached.
- CI uses a matrix strategy to build both Ubuntu and UBI variants; GHA caches are scoped per variant to avoid conflicts.
