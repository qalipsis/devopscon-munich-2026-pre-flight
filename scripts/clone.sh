#!/usr/bin/env bash
# Step 5: downloads the workshop repository next to this one, on its start branch, so you are ready the
# moment the workshop begins.
#
#   scripts/clone.sh              into ../devopscon-munich-2026
#   scripts/clone.sh <folder>     into another folder
#
# Running it again is safe: an existing copy is only updated with the new commits, never overwritten.
set -uo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"

WORKSHOP_REPOSITORY=https://github.com/qalipsis/devopscon-munich-2026.git
# Never ask for a password: the repository is public, or not published yet.
export GIT_TERMINAL_PROMPT=0

main() {
  local target="${1:-$ROOT_DIR/../devopscon-munich-2026}"
  command -v git >/dev/null 2>&1 || die "Git is not installed. Install it, then run this step again."
  title "Getting the workshop repository"

  if [[ -d "$target/.git" ]]; then
    target="$(cd "$target" && pwd)"
    if git -C "$target" fetch --quiet --tags origin 2>/dev/null; then
      ok "Already here, and up to date with the server: $target"
    else
      note "Already here: $target. It could not be updated now; it will be on the day."
    fi
  elif ! git ls-remote --quiet --exit-code "$WORKSHOP_REPOSITORY" HEAD >/dev/null 2>&1; then
    note "The workshop repository is not published yet. It will be on the day: run scripts/clone.sh again then."
    return 0
  elif git clone --quiet "$WORKSHOP_REPOSITORY" "$target"; then
    target="$(cd "$target" && pwd)"
    ok "Downloaded to $target, on the branch $(git -C "$target" branch --show-current)."
  else
    fail "The download failed. Check your network and run this step again."
    return 1
  fi

  info ""
  info "On the day, in a terminal:"
  info "  cd \"$target\""
  info "  ./up.sh"
  info "Then open the wizard: http://localhost:1313"
}

main "$@"
