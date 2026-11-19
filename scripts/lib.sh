#!/usr/bin/env bash
# Shared helpers of the pre-flight scripts. Source it, do not run it.

# Git Bash on Windows rewrites arguments that look like paths. Docker gets container paths, so stop it.
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC2034  # used by the step scripts
IMAGES_LOCK="$ROOT_DIR/images.lock"
# shellcheck disable=SC2034
WARMUP_DIR="$ROOT_DIR/warmup"
# Same volume as ./gate.sh of the workshop: what is downloaded here is found there.
# shellcheck disable=SC2034
GRADLE_CACHE_VOLUME=workshop-gradle-cache
# shellcheck disable=SC2034
GRADLE_IMAGE=eclipse-temurin:21-jdk
CONTACT=eric.jesse@qalipsis.com

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  BOLD=$'\033[1m' GREEN=$'\033[32m' YELLOW=$'\033[33m' RED=$'\033[31m' RESET=$'\033[0m'
else
  BOLD='' GREEN='' YELLOW='' RED='' RESET=''
fi

info() { printf '%s\n' "$*"; }
title() { printf '\n%s%s%s\n' "$BOLD" "$*" "$RESET"; }
ok() { printf '  %s[ OK ]%s %s\n' "$GREEN" "$RESET" "$*"; }
note() { printf '  %s[NOTE]%s %s\n' "$YELLOW" "$RESET" "$*"; }
fail() { printf '  %s[FAIL]%s %s\n' "$RED" "$RESET" "$*"; }
warn() { printf '%sWARNING:%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
die() {
  printf '%sERROR:%s %s\n' "$RED" "$RESET" "$*" >&2
  printf 'Questions? Write to %s\n' "$CONTACT" >&2
  exit 1
}

require_docker() {
  command -v docker >/dev/null 2>&1 || die "Docker is not installed. Install Docker first, then start this script again."
  docker info >/dev/null 2>&1 || die "Docker is installed, but it does not answer. Start Docker, then start this script again."
}

# A folder of this computer, written the way Docker expects it in a volume mount.
# Git Bash on Windows knows "/c/Users/...", Docker needs "C:/Users/...".
host_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1"
  else
    printf '%s\n' "$1"
  fi
}

# Images of images.lock, of one kind: platform, sandbox or pipeline.
images_of() {
  awk -v kind="$1" '$1 == kind { print $2 }' "$IMAGES_LOCK"
}

# Major version of the java command, 0 when there is none.
java_major() {
  local version
  command -v java >/dev/null 2>&1 || { echo 0; return; }
  version="$(java -version 2>&1 | awk -F'"' '/version/ { print $2; exit }')"
  [[ "$version" == 1.* ]] && version="${version#1.}"
  version="${version%%[.+-]*}"
  [[ "$version" =~ ^[0-9]+$ ]] && echo "$version" || echo 0
}
