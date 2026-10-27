#!/usr/bin/env bash
# simple-spec-init.sh: install Simple Spec into the current directory.
# Compatible with bash 3.2 (macOS default). Never overwrites existing files.

SCAFFOLD_DIR="${HOME}/.simple-spec-scaffolding"

set -u

MARKER_START='<!-- simple-spec:start -->'
MARKER_END='<!-- simple-spec:end -->'
DEFAULT_SPECS_DIR='specs'
SKILLS='explore propose implement archive'

DRY_RUN=0
ASSUME_YES=0
INSTALL_SCAFFOLDING=0

CREATED=()
APPENDED=()
SKIPPED=()

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--yes] [--install-scaffolding] [--help]

Install Simple Spec (.simple-spec/, AGENTS.md, and the specification folder)
into the current directory from: $SCAFFOLD_DIR
Existing files are never overwritten.

Options:
  --dry-run              Show what would be created, appended, or skipped; write nothing.
  --yes                  Do not prompt; use the default specification folder ($DEFAULT_SPECS_DIR).
  --install-scaffolding  Populate $SCAFFOLD_DIR from this repository's scaffolding/ and exit.
                         If it exists, choose to add missing files only or override it
                         (--yes adds missing files only).
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
  cat "$SCAFFOLD_DIR/AGENTS.md"
  ends_without_newline "$SCAFFOLD_DIR/AGENTS.md" && printf '\n'
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

install_scaffolding() {
  local repo src tmp f s
  repo="$(cd "$(dirname "$0")" && pwd -P)" || die "Cannot resolve the script directory."
  src="$repo/scaffolding"
  for f in .simple-spec/config.yaml AGENTS.md; do
    [ -f "$src/$f" ] || die "Missing '$src/$f'; run --install-scaffolding from a Simple Spec checkout."
  done
  for s in $SKILLS; do
    [ -f "$src/.simple-spec/skills/$s.md" ] || die "Missing '$src/.simple-spec/skills/$s.md'."
  done
  [ -d "$src/specs" ] || die "Missing '$src/specs/'."
  case "$SCAFFOLD_DIR" in
    ''|/|"$HOME"|"$HOME/") die "Refusing to use SCAFFOLD_DIR='$SCAFFOLD_DIR'." ;;
  esac

  info "Scaffolding source: $src"
  if [ -d "$repo/.simple-spec" ] && ! diff -rq "$repo/.simple-spec" "$src/.simple-spec" > /dev/null 2>&1; then
    warn "scaffolding/.simple-spec/ differs from this repository's .simple-spec/; the scaffolding copy will be installed."
  fi

  if [ ! -e "$SCAFFOLD_DIR" ] && [ ! -L "$SCAFFOLD_DIR" ]; then
    info "This will create the scaffolding at $SCAFFOLD_DIR."
    if [ "$DRY_RUN" -eq 1 ]; then
      info "Dry run: nothing was written."
      return 0
    fi
    confirm "Install scaffolding into $SCAFFOLD_DIR?" || { info "Aborted; nothing was written."; return 0; }
    replace_scaffolding "$src"
    return
  fi

  [ -d "$SCAFFOLD_DIR" ] || die "'$SCAFFOLD_DIR' exists but is not a directory."
  list_scaffolding_diff "$src"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "Dry run: nothing was written."
    return 0
  fi
  case "$(choose_scaffolding_mode)" in
    missing) add_missing_scaffolding "$src" ;;
    override) replace_scaffolding "$src" ;;
    *) info "Aborted; nothing was written." ;;
  esac
}

# list_scaffolding_diff <src>: print which scaffolding entries are missing or already present.
list_scaffolding_diff() {
  local src="$1" rel missing=0 present=0
  info "Scaffolding already exists at $SCAFFOLD_DIR."
  while IFS= read -r rel; do
    if [ -e "$SCAFFOLD_DIR/$rel" ]; then
      present=$((present + 1))
    else
      [ "$missing" -eq 0 ] && info "Missing:"
      info "  - $rel"
      missing=$((missing + 1))
    fi
  done <<EOF2
$(scaffolding_entries "$src")
EOF2
  [ "$missing" -eq 0 ] && info "Missing: none"
  info "Already present: $present"
}

# scaffolding_entries <src>: relative paths of all directories and files, parents first.
scaffolding_entries() {
  (cd "$1" && find . -mindepth 1 \( -type d -o -type f \) | sed 's|^\./||' | LC_ALL=C sort)
}

# choose_scaffolding_mode: print missing, override, or cancel.
choose_scaffolding_mode() {
  local answer
  if [ "$ASSUME_YES" -eq 1 ]; then
    printf 'missing'
    return
  fi
  if ! is_tty; then
    info "No terminal; cancelling (use --yes to add missing files only)." >&2
    printf 'cancel'
    return
  fi
  while :; do
    read -r -p "[a]dd missing files only, [o]verride the installation, or [c]ancel? [a/o/C] " answer || { printf 'cancel'; return; }
    case "$answer" in
      a|A) printf 'missing'; return ;;
      o|O) printf 'override'; return ;;
      ''|c|C) printf 'cancel'; return ;;
      *) info "Please answer a, o, or c." >&2 ;;
    esac
  done
}

add_missing_scaffolding() {
  local src="$1" rel added=0
  while IFS= read -r rel; do
    [ -e "$SCAFFOLD_DIR/$rel" ] && continue
    if [ -d "$src/$rel" ]; then
      mkdir "$SCAFFOLD_DIR/$rel" || die "Cannot create '$SCAFFOLD_DIR/$rel'."
    else
      cp "$src/$rel" "$SCAFFOLD_DIR/$rel" || die "Cannot copy '$rel' into '$SCAFFOLD_DIR'."
    fi
    info "  added   $rel"
    added=$((added + 1))
  done <<EOF2
$(scaffolding_entries "$src")
EOF2
  if [ "$added" -eq 0 ]; then
    info "Nothing to add; the scaffolding at $SCAFFOLD_DIR is complete."
  else
    info "Added $added missing item(s) to $SCAFFOLD_DIR; existing files were kept."
  fi
}

replace_scaffolding() {
  local src="$1" tmp="$SCAFFOLD_DIR.tmp.$$"
  rm -rf "$tmp"
  mkdir -p "$tmp" \
    && cp -R "$src/.simple-spec" "$tmp/.simple-spec" \
    && cp "$src/AGENTS.md" "$tmp/AGENTS.md" \
    && cp -R "$src/specs" "$tmp/specs" \
    || { rm -rf "$tmp"; die "Cannot build the scaffolding in '$tmp'."; }
  if [ -e "$SCAFFOLD_DIR" ]; then
    rm -rf "$SCAFFOLD_DIR" || { rm -rf "$tmp"; die "Cannot remove the old scaffolding at '$SCAFFOLD_DIR'."; }
  fi
  mv "$tmp" "$SCAFFOLD_DIR" || die "Cannot move '$tmp' to '$SCAFFOLD_DIR'."
  info "Scaffolding installed at $SCAFFOLD_DIR."
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
      --install-scaffolding) INSTALL_SCAFFOLDING=1 ;;
      -h|--help) usage; exit 0 ;;
      *) usage >&2; exit 2 ;;
    esac
  done

  if [ "$INSTALL_SCAFFOLDING" -eq 1 ]; then
    install_scaffolding
    exit $?
  fi

  [ -d "$SCAFFOLD_DIR" ] || die "Scaffolding not found at $SCAFFOLD_DIR. Run '$(basename "$0") --install-scaffolding' from a Simple Spec checkout."
  for s in config.yaml $(for k in $SKILLS; do printf 'skills/%s.md ' "$k"; done); do
    [ -f "$SCAFFOLD_DIR/.simple-spec/$s" ] || die "Scaffolding is incomplete: missing $SCAFFOLD_DIR/.simple-spec/$s. Re-run --install-scaffolding."
  done
  [ -f "$SCAFFOLD_DIR/AGENTS.md" ] || die "Scaffolding is incomplete: missing $SCAFFOLD_DIR/AGENTS.md. Re-run --install-scaffolding."

  TARGET="$(pwd -P)" || die "Cannot resolve the current directory."
  info "Simple Spec files will be created in: $TARGET"
  if [ "$TARGET" = "$(cd "$(dirname "$0")" && pwd -P)" ]; then
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
    config_src="$SCAFFOLD_DIR/.simple-spec/config.yaml"
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
  install_file ".simple-spec/config.yaml" config "$SCAFFOLD_DIR/.simple-spec/config.yaml"
  for s in $SKILLS; do
    install_file ".simple-spec/skills/$s.md" copy "$SCAFFOLD_DIR/.simple-spec/skills/$s.md"
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
