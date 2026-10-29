#!/usr/bin/env bash
# simple-spec-init.sh: install Simple Spec into the current directory.
# Compatible with bash 3.2 (macOS default). Never overwrites existing files.

set -u

MARKER_START='<!-- simple-spec:start -->'
MARKER_END='<!-- simple-spec:end -->'
DEFAULT_SPECS_DIR='specs'
SKILLS='explore propose implement archive'

DRY_RUN=0
ASSUME_YES=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)" || { printf 'Error: Cannot resolve the script directory.\n' >&2; exit 1; }

CREATED=()
APPENDED=()
SKIPPED=()

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--yes] [--help]

Install Simple Spec (.simple-spec/, AGENTS.md, and the specification folder)
into the current directory using files beside this script.
Existing files are never overwritten.

Options:
  --dry-run              Show what would be created, appended, or skipped; write nothing.
  --yes                  Do not prompt; use the default specification folder ($DEFAULT_SPECS_DIR).
  --help                 Show this help.
EOF
}

info() { printf '%s\n' "$*"; }
warn() { printf 'Warning: %s\n' "$*" >&2; }
die() { printf 'Error: %s\n' "$1" >&2; exit "${2:-1}"; }

is_tty() { [ -t 0 ]; }

in_list() { # in_list <needle> <items...>
  local needle="$1" item
  shift
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

confirm() { # confirm <question>; default is no
  local answer
  if [ "$ASSUME_YES" -eq 1 ]; then
    return 0
  fi
  if ! is_tty; then
    info "$1 [y/N] (no terminal; defaulting to N; use --yes to proceed)"
    return 1
  fi
  read -r -p "$1 [y/N] " answer || return 1
  case "$answer" in
    y|Y|yes|Yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

# config_value <file> <subsection|""> <key>: read a scalar under the top-level `specs:` block.
config_value() {
  awk -v want_sub="$2" -v key="$3" '
    function val(line) {
      sub(/^[^:]*:[ \t]*/, "", line)
      sub(/[ \t]+#.*$/, "", line)
      sub(/[ \t]+$/, "", line)
      gsub(/^["\047]|["\047]$/, "", line)
      return line
    }
    /^[^ \t#]/ { in_specs = ($0 ~ /^specs:[ \t]*$/); sub_sec = ""; next }
    !in_specs { next }
    /^  [^ \t#]/ {
      if ($0 ~ /^  [A-Za-z_]+:[ \t]*$/) { s = $0; sub(/^  /, "", s); sub(/:.*/, "", s); sub_sec = s }
      else sub_sec = ""
      if (want_sub == "" && $0 ~ ("^  " key ":")) { print val($0); exit }
      next
    }
    /^    [^ \t#]/ {
      if (want_sub != "" && sub_sec == want_sub && $0 ~ ("^    " key ":")) { print val($0); exit }
    }
  ' "$1"
}

# write_config <src> <dst> <specs dir>: copy config, setting specs.directory.
write_config() {
  awk -v dir="$3" '
    /^[^ \t#]/ { in_specs = ($0 ~ /^specs:[ \t]*$/) }
    in_specs && !done && /^  directory:/ { print "  directory: \"" dir "\""; done = 1; next }
    { print }
    END { if (!done) exit 3 }
  ' "$1" > "$2"
}

# normalize_specs_dir <input>: validate and set SPECS_DIR (trailing slashes removed).
normalize_specs_dir() {
  local d="$1" rest c first
  while [ "${d%/}" != "$d" ]; do d="${d%/}"; done
  case "$d" in
    ''|/*) return 1 ;;
    *[!A-Za-z0-9._/-]*) return 1 ;;
  esac
  rest="$d"
  first="${d%%/*}"
  case "$first" in
    .simple-spec|.git) return 1 ;;
  esac
  while :; do
    c="${rest%%/*}"
    case "$c" in
      ''|.|..) return 1 ;;
    esac
    [ "$rest" = "$c" ] && break
    rest="${rest#*/}"
  done
  SPECS_DIR="$d"
  return 0
}

# check_path_safe <relative path>: every existing component must be a directory inside TARGET.
check_path_safe() {
  local rest="$1" path="" c real
  while [ -n "$rest" ]; do
    c="${rest%%/*}"
    if [ "$rest" = "$c" ]; then rest=""; else rest="${rest#*/}"; fi
    path="${path:+$path/}$c"
    [ -e "$path" ] || [ -L "$path" ] || continue
    if [ ! -d "$path" ]; then
      die "'$path' exists but is not a directory."
    fi
    real="$(cd "$path" && pwd -P)" || die "Cannot access '$path'."
    case "$real/" in
      "$TARGET"/*) ;;
      *) die "'$path' resolves outside $TARGET ($real)." ;;
    esac
  done
}

record_created() { in_list "$1" ${CREATED[@]+"${CREATED[@]}"} || CREATED+=("$1"); }

report() { # report <action> <path>
  if [ "$DRY_RUN" -eq 1 ]; then
    case "$1" in
      created) info "  would create  $2" ;;
      appended) info "  would append  $2" ;;
      skipped) info "  would skip    $2 (exists)" ;;
    esac
  else
    case "$1" in
      created) info "  created       $2" ;;
      appended) info "  appended      $2" ;;
      skipped) info "  skipped       $2 (exists)" ;;
    esac
  fi
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  if [ "${#CREATED[@]}" -gt 0 ] || [ "${#APPENDED[@]}" -gt 0 ]; then
    printf 'Created before the failure: %s\n' "${CREATED[*]-} ${APPENDED[*]-}" >&2
  fi
  exit 1
}

ensure_dir() { # ensure_dir <relative dir>, creating parents
  local rest="$1" path="" c
  while [ -n "$rest" ]; do
    c="${rest%%/*}"
    if [ "$rest" = "$c" ]; then rest=""; else rest="${rest#*/}"; fi
    path="${path:+$path/}$c"
    if [ -d "$path" ] || in_list "$path/" ${CREATED[@]+"${CREATED[@]}"}; then
      continue
    fi
    [ -e "$path" ] && fail "'$path' exists but is not a directory."
    if [ "$DRY_RUN" -eq 0 ]; then
      mkdir "$path" || fail "Cannot create directory '$path'."
    fi
    record_created "$path/"
    report created "$path/"
  done
}

parent_of() {
  case "$1" in
    */*) printf '%s' "${1%/*}" ;;
    *) printf '' ;;
  esac
}

# install_file <relative path> <copy|config|empty> [src]
install_file() {
  local dst="$1" mode="$2" src="${3:-}" parent
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    [ -f "$dst" ] || fail "'$dst' exists but is not a regular file."
    SKIPPED+=("$dst")
    report skipped "$dst"
    return
  fi
  parent="$(parent_of "$dst")"
  [ -n "$parent" ] && ensure_dir "$parent"
  if [ "$DRY_RUN" -eq 0 ]; then
    case "$mode" in
      copy) cp "$src" "$dst" || fail "Cannot copy '$src' to '$dst'." ;;
      config)
        write_config "$src" "$dst.tmp.$$" "$SPECS_DIR" || {
          rm -f "$dst.tmp.$$"
          fail "Cannot set specs.directory in '$dst' (no 'directory:' line under 'specs:' in $src)."
        }
        mv "$dst.tmp.$$" "$dst" || fail "Cannot write '$dst'."
        ;;
      empty) : > "$dst" || fail "Cannot create '$dst'." ;;
    esac
  fi
  record_created "$dst"
  report created "$dst"
}

ends_without_newline() { # true if the file is non-empty and its last byte is not a newline
  local n
  [ -s "$1" ] || return 1
  n=$(tail -c 1 "$1" | wc -l)
  [ $((n + 0)) -eq 0 ]
}

write_agents_block() {
  printf '%s\n' "$MARKER_START"
  cat "$SCRIPT_DIR/AGENTS.md"
  ends_without_newline "$SCRIPT_DIR/AGENTS.md" && printf '\n'
  printf '%s\n' "$MARKER_END"
}

install_agents() {
  local dst="AGENTS.md"
  if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
    if [ "$DRY_RUN" -eq 0 ]; then
      write_agents_block > "$dst" || fail "Cannot create '$dst'."
    fi
    record_created "$dst"
    report created "$dst"
    return
  fi
  [ -f "$dst" ] || fail "'$dst' exists but is not a regular file."
  if grep -qF -- "$MARKER_START" "$dst"; then
    SKIPPED+=("$dst (Simple Spec block already present)")
    report skipped "$dst"
    return
  fi
  if [ "$DRY_RUN" -eq 0 ]; then
    {
      ends_without_newline "$dst" && printf '\n'
      printf '\n'
      write_agents_block
    } >> "$dst" || fail "Cannot append to '$dst'."
  fi
  APPENDED+=("$dst")
  report appended "$dst"
}

# print_tree: render created/appended paths as a tree rooted at TARGET.
print_tree() {
  {
    local p
    for p in ${CREATED[@]+"${CREATED[@]}"}; do printf 'C|%s\n' "$p"; done
    for p in ${APPENDED[@]+"${APPENDED[@]}"}; do printf 'A|%s\n' "$p"; done
  } | LC_ALL=C sort -t '|' -k 2 | awk -F '|' -v root="$TARGET" '
    function add(p, dir,   par) {
      if (p in seen) { if (dir) isdir[p] = 1; return }
      par = p
      if (index(p, "/")) sub(/\/[^\/]*$/, "", par); else par = "."
      if (par != ".") add(par, 1)
      seen[p] = 1
      if (dir) isdir[p] = 1
      kids[par] = kids[par] SUBSEP p
    }
    function show(par, prefix,   n, arr, i, c, name, tag) {
      n = split(kids[par], arr, SUBSEP)
      for (i = 2; i <= n; i++) {
        c = arr[i]
        name = c
        sub(/.*\//, "", name)
        if (isdir[c]) name = name "/"
        tag = ""
        if (state[c] == "A") tag = "  (appended)"
        else if (!(c in state)) tag = "  (existing)"
        print prefix (i == n ? "└── " : "├── ") name tag
        if (isdir[c]) show(c, prefix (i == n ? "    " : "│   "))
      }
    }
    {
      p = $2; dir = 0
      if (p ~ /\/$/) { p = substr(p, 1, length(p) - 1); dir = 1 }
      state[p] = $1
      add(p, dir)
    }
    END { print root "/"; show(".", "") }
  '
}

prompt_specs_dir() {
  local answer
  if [ "$ASSUME_YES" -eq 1 ] || ! is_tty; then
    normalize_specs_dir "$DEFAULT_SPECS_DIR"
    return
  fi
  while :; do
    read -r -p "Specification folder [$DEFAULT_SPECS_DIR]: " answer || die "No input received."
    answer="${answer#"${answer%%[![:space:]]*}"}"
    answer="${answer%"${answer##*[![:space:]]}"}"
    [ -z "$answer" ] && answer="$DEFAULT_SPECS_DIR"
    normalize_specs_dir "$answer" && return
    info "Invalid folder '$answer': use a relative path with letters, digits, '.', '_', '-', '/'; no '..', '.', '.git', or '.simple-spec'."
  done
}

main() {
  local arg config_src functional technical s existing_specs

  for arg in "$@"; do
    case "$arg" in
      --dry-run) DRY_RUN=1 ;;
      --yes) ASSUME_YES=1 ;;
      -h|--help) usage; exit 0 ;;
      *) usage >&2; exit 2 ;;
    esac
  done

  [ -f "$SCRIPT_DIR/.simple-spec/config.yaml" ] || die "Missing '$SCRIPT_DIR/.simple-spec/config.yaml'. Run this script from a complete Simple Spec checkout."
  for s in config.yaml $(for k in $SKILLS; do printf 'skills/%s.md ' "$k"; done); do
    [ -f "$SCRIPT_DIR/.simple-spec/$s" ] || die "Missing '$SCRIPT_DIR/.simple-spec/$s'."
  done
  [ -f "$SCRIPT_DIR/AGENTS.md" ] || die "Missing '$SCRIPT_DIR/AGENTS.md'."

  if is_tty; then clear; fi
  cat <<'BANNER'
         _                 __
   _____(_)___ ___  ____  / /__        _________  ___  _____
  / ___/ / __ `__ \/ __ \/ / _ \______/ ___/ __ \/ _ \/ ___/
 (__  ) / / / / / / /_/ / /  __/_____(__  ) /_/ /  __/ /__
/____/_/_/ /_/ /_/ .___/_/\___/     /____/ .___/\___/\___/
                /_/                     /_/
BANNER
  sleep 2

  TARGET="$(pwd -P)" || die "Cannot resolve the current directory."
  info "Simple Spec files will be created in: $TARGET"
  if [ "$TARGET" = "$SCRIPT_DIR" ]; then
    warn "this is the Simple Spec repository itself; its AGENTS.md would receive an appended block."
  fi

  check_path_safe ".simple-spec"
  if [ -e ".simple-spec/config.yaml" ] || [ -L ".simple-spec/config.yaml" ]; then
    [ -f ".simple-spec/config.yaml" ] || die "'.simple-spec/config.yaml' exists but is not a regular file."
    config_src=".simple-spec/config.yaml"
    existing_specs="$(config_value "$config_src" "" directory)"
    [ -n "$existing_specs" ] || die "Existing .simple-spec/config.yaml has no readable specs.directory; fix it and re-run."
    normalize_specs_dir "$existing_specs" || die "Existing specs.directory '$existing_specs' is not a safe relative path; fix .simple-spec/config.yaml and re-run."
    info "Using the specification folder from the existing config: $SPECS_DIR"
  else
    config_src="$SCRIPT_DIR/.simple-spec/config.yaml"
    prompt_specs_dir
    info "Specification folder: $SPECS_DIR"
  fi
  check_path_safe "$SPECS_DIR"

  functional="$(config_value "$config_src" functional file)"
  technical="$(config_value "$config_src" technical file)"
  for s in "$functional" "$technical"; do
    case "$s" in
      ''|*/*|.|..|*[!A-Za-z0-9._-]*) die "Invalid specification filename '$s' in $config_src." ;;
    esac
  done

  if [ "$DRY_RUN" -eq 1 ]; then
    info "Dry run: nothing will be written."
  elif ! confirm "Create Simple Spec files in $TARGET (specification folder: $SPECS_DIR)?"; then
    info "Aborted; nothing was written."
    exit 0
  fi

  info ""
  install_file ".simple-spec/config.yaml" config "$SCRIPT_DIR/.simple-spec/config.yaml"
  for s in $SKILLS; do
    install_file ".simple-spec/skills/$s.md" copy "$SCRIPT_DIR/.simple-spec/skills/$s.md"
  done
  install_agents
  ensure_dir "$SPECS_DIR"
  install_file "$SPECS_DIR/$functional" empty
  install_file "$SPECS_DIR/$technical" empty
  install_file "$SPECS_DIR/changelog.md" empty
  install_file "$SPECS_DIR/changes/WIP/.gitkeep" empty
  install_file "$SPECS_DIR/changes/archived/.gitkeep" empty

  info ""
  if [ "$DRY_RUN" -eq 1 ]; then
    info "Would install:"
  else
    info "Installed:"
  fi
  if [ "${#CREATED[@]}" -eq 0 ] && [ "${#APPENDED[@]}" -eq 0 ]; then
    info "  nothing; Simple Spec is already installed here."
  else
    print_tree
  fi
  if [ "${#SKIPPED[@]}" -gt 0 ]; then
    info ""
    info "Skipped (already exist):"
    for s in "${SKIPPED[@]}"; do info "  - $s"; done
  fi

  [ "$DRY_RUN" -eq 1 ] && exit 0
  info ""
  info "Next steps:"
  info "  - You can edit .simple-spec/config.yaml to change the language, history mode, and specification templates."
  info "  - Start a feature by asking your agent: \"I want to explore the development of a new feature x...\""
}

main "$@"
