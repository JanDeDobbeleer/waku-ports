# Shared by the commit-msg hook and the pull request check.
CONVENTIONAL_TYPES="feat fix refactor perf test docs build ci chore style revert"

# is_conventional <subject>: type(scope)?!?: text. The scope is free text (a shell name or area).
is_conventional() {
  case "$1" in
    "Merge "* | "Revert \""* | "fixup! "* | "squash! "* | "amend! "*) return 0 ;;
  esac
  printf '%s\n' "$1" | grep -Eq '^(feat|fix|refactor|perf|test|docs|build|ci|chore|style|revert)(\([a-z0-9_./-]+\))?!?: .+'
}
