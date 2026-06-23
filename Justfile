set lists

fedora_version := env("FEDORA_VERSION", "44")
registry := env("CONTAINER_REGISTRY", "ghcr.io")
ns := env("CONTAINER_NS", "annie444")
tag := env("CONTAINER_TAG", "latest")
prefix := env("CONTAINER_PREFIX", "linux")
suffix := env("CONTAINER_SUFFIX", "-toolbox")

container_exec := if which("podman") != "" { "podman" } else { "docker" }

[default]
[private]
default:
    @just --list

[group("Linux")]
build:
    #!/usr/bin/env bash
    PLATFORM="${CONTAINER_PLATFORM}"
    if [[ -z "${PLATFORM:-}" ]]; then
        case "$(arch)" in
            aarch64 | arm64)
                PLATFORM="linux/arm64"
                ;;
            x86_64 | amd64)
                PLATFORM="linux/amd64"
                ;;
        esac
    fi
    {{ container_exec }} build \
        --platform="$PLATFORM" \
        --build-arg=FEDORA_VERSION={{ fedora_version }} \
        --tag="{{ registry }}/{{ ns }}/{{ prefix }}{{ suffix }}:{{ tag }}" \
        --file Containerfile.linux .
