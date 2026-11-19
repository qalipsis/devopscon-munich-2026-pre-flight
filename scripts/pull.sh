#!/usr/bin/env bash
# Step 3: downloads the container images of the workshop.
#
#   scripts/pull.sh                  open-source images only
#   scripts/pull.sh --accept-terms   also the three workshop platform images: by giving this option,
#                                    you accept their terms (README.md, "Terms of the workshop images")
#
# Running it again is safe: images already here are checked, not downloaded again.
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"

pull_all() {
  local images=("$@") index=0 image failures=0
  for image in "${images[@]}"; do
    index=$((index + 1))
    printf '  [%d/%d] %s ... ' "$index" "${#images[@]}" "$image"
    if docker pull -q "$image" >/dev/null 2>&1; then
      printf '%sdone%s\n' "$GREEN" "$RESET"
    else
      printf '%sfailed%s\n' "$RED" "$RESET"
      failures=$((failures + 1))
    fi
  done
  return "$failures"
}

main() {
  local accept=false
  [[ "${1:-}" == --accept-terms ]] && accept=true
  require_docker
  [[ -f "$IMAGES_LOCK" ]] || die "images.lock is missing. Download this repository again."

  local images=() image
  while IFS= read -r image; do images+=("$image"); done < <(images_of sandbox; images_of pipeline)
  if [[ "$accept" == true ]]; then
    while IFS= read -r image; do images+=("$image"); done < <(images_of platform)
  else
    note "The workshop platform images are not downloaded: their terms were not accepted."
  fi

  title "Downloading ${#images[@]} images"
  info "Large images take several minutes. You can stop with Ctrl+C and start again later."
  local status=0
  pull_all "${images[@]}" || status=$?

  info ""
  if ((status == 0)); then
    info "${GREEN}All images are on this computer.${RESET}"
  else
    info "${RED}$status image(s) could not be downloaded.${RESET} Check your network and run this step again."
  fi
  return "$status"
}

main "$@"
