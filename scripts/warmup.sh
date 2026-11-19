#!/usr/bin/env bash
# Step 4: builds a small Gradle project that uses exactly the same tools and libraries as the
# workshop. Gradle downloads them once and keeps them, so the build is fast during the workshop.
#
# Where Gradle runs is decided the same way as in the workshop:
#   - Java installed (any version): on this computer. Files go to ~/.gradle.
#   - No Java: in a container. Files go to the Docker volume "workshop-gradle-cache".
# Force one or the other with GRADLE_RUNNER=local or GRADLE_RUNNER=docker.
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"

pick_runner() {
  local runner="${GRADLE_RUNNER:-auto}"
  if [[ "$runner" == auto ]]; then
    (($(java_major) >= 8)) && runner=local || runner=docker
  fi
  printf '%s\n' "$runner"
}

# Hides two harmless messages of the annotation processors, which only worry people.
quiet_gradle() {
  local status
  "$@" 2>&1 | { grep -vE "RELEASE_20|Using JSON as default serializer|^$" || true; }
  status="${PIPESTATUS[0]}"
  return "$status"
}

main() {
  local runner
  runner="$(pick_runner)"
  title "Preparing the Gradle build"

  case "$runner" in
    local)
      info "Gradle runs on this computer, with your Java $(java_major). Files go to ~/.gradle."
      (cd "$WARMUP_DIR" && quiet_gradle ./gradlew --console=plain --quiet build -x test)
      ;;
    docker)
      require_docker
      info "Gradle runs in the container $GRADLE_IMAGE. Files go to the Docker volume $GRADLE_CACHE_VOLUME."
      quiet_gradle docker run --rm --init \
        -v "$(host_path "$WARMUP_DIR"):/warmup" \
        -v "$GRADLE_CACHE_VOLUME:/gradle-home" \
        -e GRADLE_USER_HOME=/gradle-home \
        -w /warmup \
        "$GRADLE_IMAGE" ./gradlew --console=plain --quiet build -x test
      ;;
    *) die "GRADLE_RUNNER must be 'local', 'docker' or 'auto'." ;;
  esac
  info "${GREEN}Gradle has everything the workshop needs.${RESET}"
}

main "$@"
