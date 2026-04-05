# Agent sandbox containers with Apple Container + devenv

Goal: isolate agent work (pi, claude code, etc.) per-project in disposable Linux containers using Apple Container on macOS Tahoe.

## Architecture

```
Layer 2: project sandbox (per repo)
  - Pre-built devenv environment from project's devenv.nix
  - Agent binary (pi, claude code, etc.)
  - Optional: project source baked in

Layer 1: devenv-container (shared base)
  - Debian minimal
  - Nix (single-user install)
  - devenv CLI

Layer 0: Apple Container runtime (macOS Tahoe native)
  - Lightweight Linux VM per container
  - OCI-compatible, kernel-enforced isolation
  - No .ssh, .aws, or homedir secrets accessible
```

## Layer 1: devenv-container

Repo: `github.com/otahontas/devenv-container` (new)

```dockerfile
FROM debian:minimal-slim

RUN apt-get update && apt-get install -y curl xz-utils ca-certificates && \
    sh <(curl -L https://nixos.org/nix/install) --daemonless && \
    rm -rf /var/lib/apt/lists/*

RUN . /nix/var/nix/profiles/default/etc/profile.d/nix.sh && \
    nix profile install github:cachix/devenv/latest

CMD ["bash"]
```

Build and push:

```bash
container build -t ghcr.io/otahontas/devenv-container .
container push ghcr.io/otahontas/devenv-container
```

Built once, shared by all projects. Rebuild only when Nix or devenv versions change.

## Layer 2: per-project sandbox

Each project repo (e.g. `kanttiinit-cli`) gets a `Containerfile.sandbox`:

```dockerfile
FROM ghcr.io/otahontas/devenv-container

COPY devenv.nix devenv.yaml devenv.lock ./
RUN . /nix/var/nix/profiles/default/etc/profile.d/nix.sh && \
    devenv ci

RUN . /nix/var/nix/profiles/default/etc/profile.d/nix.sh && \
    nix profile install github:mariozechner/pi-coding-agent

CMD ["bash", "-c", "source /nix/var/nix/profiles/default/etc/profile.d/nix.sh && devenv shell"]
```

Build and run:

```bash
container build -t kanttiinit-sandbox -f Containerfile.sandbox .
container run -it kanttiinit-sandbox
```

## Usage modes

### Mount mode (local dev)

```bash
container run -it \
  --volume $(pwd):/project \
  kanttiinit-sandbox
```

- Host editor works on files normally
- Agent sees only `/project` and the nix store
- Delete container when done: `container delete kanttiinit-sandbox`

### Git-only mode (full isolation)

```bash
container run -it \
  -e GITHUB_TOKEN=ghp_... \
  kanttiinit-sandbox \
  bash -c "git clone https://github.com/otahontas/kanttiinit-cli && \
           cd kanttiinit-cli && \
           devenv shell -- pi agent"
```

- Agent clones inside, pushes PR via HTTPS + scoped token
- No host filesystem access at all
- When container dies, everything is gone

## What the agent can't touch

- `~/.ssh` — doesn't exist in container
- `~/.aws` — doesn't exist
- Other repos, dotfiles, credentials — invisible
- Host filesystem (unless explicitly mounted with `--volume`)

## Relation to existing tools

- **devenv-base** (`github.com/otahontas/devenv-base`): unchanged, still used as devenv input in projects
- **Agent Safehouse**: macOS sandbox-exec approach, process-level only. Our approach is full VM isolation.
- **nono**: similar layered safety model but ours is simpler — just container isolation, no SDK needed.

## Open questions

- [ ] Does `devenv ci` work correctly inside the container? (needs network for nix fetches)
- [ ] How slow is the initial `container build`? The devenv closure can be large.
- [ ] Should devenv-container use NixOS instead of Debian as base? NixOS would have Nix pre-installed but images are larger.
- [ ] Persistent volumes for `/nix/store` across container runs? Avoids re-downloading on rebuild.
- [ ] Git config inside container: `.gitconfig` as env vars or baked into layer 2?
- [ ] SSH agent forwarding: `container run --ssh` for cloning private repos?
- [ ] Should `devenv-container` repo also host a GitHub Actions workflow to build + push to GHCR?
- [ ] How to handle projects that use `devenv-base` as input — does `devenv ci` resolve the input correctly inside the container?

## Next steps

1. Create `otahontas/devenv-container` repo with the Containerfile
2. Install Apple Container (`brew install container` or download from releases)
3. Build layer 1, test it: `container build` + `container run`
4. Add `Containerfile.sandbox` to `kanttiinit-cli`, build layer 2
5. Test the full flow: build, run, `devenv shell`, `pi agent`
