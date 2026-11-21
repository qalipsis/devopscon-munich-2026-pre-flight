#!/usr/bin/env bash
# Step 4: builds a small Gradle project that uses exactly the same tools and libraries as the
# workshop. Gradle downloads them once and keeps them, so the build is fast during the workshop.
#
# Gradle runs where it runs in the workshop: in a container of eclipse-temurin:21-jdk, so no Java needs to
# be installed. Files go to the Docker volume "workshop-gradle-cache", where ./gate.sh finds them.
# GRADLE_RUNNER=local prepares Gradle on this computer instead, for GATE_RUNNER=local in the workshop:
# it needs a Java (any version), and the files go to ~/.gradle.
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"

pick_runner() {
  printf '%s\n' "${GRADLE_RUNNER:-docker}"
}

# Hides two harmless messages of the annotation processors, which only worry people.
quiet_gradle() {
  local status
  # Java 24 and later warn about the native library Gradle 8 loads in its launcher: harmless.
  "$@" 2>&1 | { grep -vE "RELEASE_20|Using JSON as default serializer|^WARNING: (A restricted method|java.lang.System::load|Use --enable-native-access|Restricted methods)|^$" || true; }
  status="${PIPESTATUS[0]}"
  return "$status"
}

main() {
  local runner
  runner="$(pick_runner)"
  title "Preparing the Gradle build"

  case "$runner" in
    local)
      (($(java_major) >= 8)) || die "GRADLE_RUNNER=local needs Java on this computer. Leave it unset to use a container."
      info "Gradle runs on this computer, with your Java $(java_major). Files go to ~/.gradle."
      (cd "$WARMUP_DIR" && quiet_gradle ./gradlew --console=plain --quiet build -x test)
      ;;
    docker)
      require_docker
      info "Gradle runs in the container $GRADLE_IMAGE. Files go to the Docker volume $GRADLE_CACHE_VOLUME."
      local user=() arg
      while IFS= read -r arg; do user+=("$arg"); done < <(container_user "$GRADLE_IMAGE" "$GRADLE_CACHE_VOLUME")
      quiet_gradle docker run --rm --init \
        "${user[@]+"${user[@]}"}" \
        -v "$(host_path "$WARMUP_DIR"):/warmup" \
        -v "$GRADLE_CACHE_VOLUME:/gradle-home" \
        -e GRADLE_USER_HOME=/gradle-home \
        -w /warmup \
        "$GRADLE_IMAGE" ./gradlew --console=plain --quiet build -x test
      ;;
    *) die "GRADLE_RUNNER must be 'docker' (the default) or 'local'." ;;
  esac
  [[ "$runner" == docker ]] && prepare_local_jdk
  info "${GREEN}Gradle has everything the workshop needs.${RESET}"
}

# With a Java on this computer, whatever its version, Gradle may also run here (GATE_RUNNER=local, an IDE).
# The tiny project jdk/ makes it download now the Gradle and the JDK 21 the workshop build asks for, so a
# Java 22 or newer, which Gradle 8 cannot run on, is never a problem on the day.
prepare_local_jdk() {
  (($(java_major) >= 8)) || return 0
  info "You have Java $(java_major): Gradle and JDK 21 are also prepared for this computer, in ~/.gradle."
  (cd "$JDK_DIR" && quiet_gradle ./gradlew --console=plain --quiet prepare)
}

main "$@"
