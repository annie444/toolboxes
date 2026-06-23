set lists

fedora_version := env("FEDORA_VERSION", "44")
registry := env("CONTAINER_REGISTRY", "ghcr.io")
ns := env("CONTAINER_NS", "annie444")
tag := env("CONTAINER_TAG", "latest")
prefix := env("CONTAINER_PREFIX", "linux")
suffix := env("CONTAINER_SUFFIX", "-toolbox")
repo := env("REPO_NAME", "toolboxes")
forge := env("REPO_FORGE", "github.com")

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
    declare -a meta=(
        "com.github.containers.toolbox=true"
        "org.opencontainers.image.source=https://{{ forge }}/{{ ns }}/{{ repo }}"
        "org.opencontainers.image.url=https://{{ forge }}/{{ ns }}/{{ repo }}/pkgs/container/{{ prefix }}{{ suffix }}"
        "org.label-schema.url=https://{{ forge }}/{{ ns }}/{{ repo }}"
        "org.opencontainers.image.documentation=https://{{ forge }}/{{ ns }}/{{ repo }}?tab=readme-ov-file"
        "org.label-schema.usage=https://{{ forge }}/{{ ns }}/{{ repo }}?tab=readme-ov-file"
        "org.opencontainers.image.title='Fedora Linux toolbox'"
        "org.label-schema.name='Fedora Linux toolbox'"
        "org.opencontainers.image.description='Fedora toolbox with fish + neovim for Linux utility development'"
        "org.label-schema.description='Fedora toolbox with fish + neovim for Linux utility development'"
        "org.opencontainers.image.base.name=registry.fedoraproject.org/fedora-toolbox:{{ fedora_version }}"
    )
    declare -a annotations=()
    declare -a labels=()
    for m in "${meta[@]}"; do
        annotations+=("--annotation=${m}")
        labels+=("--label=${m}")
    done
    {{ container_exec }} build \
        --inherit-labels \
        --platform="$PLATFORM" \
        --build-arg=FEDORA_VERSION={{ fedora_version }} \
        --tag="{{ registry }}/{{ ns }}/{{ prefix }}{{ suffix }}:{{ tag }}" \
        "${annotations[@]}" \
        "${labels[@]}" \
        --file Containerfile.linux .
