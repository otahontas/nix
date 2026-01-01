# Helpers for caching command output and sourcing it later
function zcache_source() {
  if [[ $# -lt 2 ]]; then
    print -u2 "zcache_source: usage: zcache_source <cache-key> [--cwd <dir>] [--] <command> [args...]"
    return 1
  fi

  local cache_key="$1"
  shift

  local workdir=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --cwd)
        if [[ $# -lt 2 ]]; then
          print -u2 "zcache_source: --cwd requires an argument"
          return 1
        fi
        workdir="$2"
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*)
        break
        ;;
      *)
        break
        ;;
    esac
  done

  if [[ $# -eq 0 ]]; then
    print -u2 "zcache_source: missing command to execute"
    return 1
  fi

  local cache_root="${XDG_CACHE_HOME:-${HOME:-/}/.cache}/zsh-cache"
  local cache_file="${cache_root%/}/${cache_key}"
  local cache_dir="${cache_file%/*}"
  if [[ "$cache_dir" == "$cache_file" ]]; then
    cache_dir="$cache_root"
    cache_file="${cache_dir}/${cache_key}"
  fi

  if [[ ! -s "$cache_file" ]]; then
    mkdir -p "$cache_dir" || return 1

    local tmp_file
    tmp_file="$(mktemp "${cache_dir}/.${cache_key##*/}.XXXXXX")" || return 1

    if [[ -n "$workdir" ]]; then
      if ! (cd "$workdir" && "$@" >| "$tmp_file"); then
        rm -f "$tmp_file"
        return 1
      fi
    else
      if ! "$@" >| "$tmp_file"; then
        rm -f "$tmp_file"
        return 1
      fi
    fi

    mv "$tmp_file" "$cache_file"
  fi

  source "$cache_file"
}
