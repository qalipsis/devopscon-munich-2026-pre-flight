#!/usr/bin/env bash
# Step 1: checks that this computer can run the workshop. Changes nothing, installs nothing.
# Exit code 0 when everything is ready, 1 when something must be fixed first.
set -uo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/lib.sh"

MIN_MEMORY_GIB=5
# Inside Docker: images, act, Gradle in a container and the data of the sandbox during the workshop, with a margin.
MIN_DISK_GIB=15
# Outside Docker, in MB. The workshop folder: the repository, its builds (up to 450 MB after a full
# ./gradlew build) and the reports of the runs. In ~/.gradle, when Java is installed: Gradle and JDK 21,
# prepared for Gradle on this computer (step 4, jdk/).
WORKSHOP_FOLDER_MB=500
GRADLE_HOME_MB=400
# Ports the sandbox opens on this computer during the workshop.
PORTS=(1313 5432 4317 4318 8080 8081 8082 8086 8400 9094 9308 16686)
# Small image (about 2 MB) that measures the free disk space inside Docker.
DISK_PROBE_IMAGE=busybox:1.37
# Servers the next steps download from.
SERVERS=(
  "https://ghcr.io/v2/|GitHub Container Registry (workshop images)"
  "https://registry-1.docker.io/v2/|Docker Hub (open-source images)"
  "https://github.com|GitHub (the act tool)"
  "https://services.gradle.org|Gradle"
  "https://repo.maven.apache.org/maven2/|Maven Central (QALIPSIS libraries)"
  "https://api.foojay.io|Foojay (Java 21, when it is missing)"
)

FAILURES=0
failed() { fail "$*"; FAILURES=$((FAILURES + 1)); }

check_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    failed "Docker is not installed. Install Docker Desktop, OrbStack, Rancher Desktop, Colima or Docker Engine."
    return 1
  fi
  if ! docker info >/dev/null 2>&1; then
    failed "Docker is installed but does not answer. Start Docker and run this check again."
    return 1
  fi
  ok "Docker answers: $(docker version --format '{{.Server.Version}}' 2>/dev/null) on $(docker info --format '{{.OperatingSystem}}' 2>/dev/null)."
  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose is available: $(docker compose version --short 2>/dev/null)."
  else
    failed "'docker compose' does not work. Install the Docker Compose plugin (version 2)."
  fi
}

check_architecture() {
  local arch
  arch="$(docker info --format '{{.Architecture}}' 2>/dev/null)"
  case "$arch" in
    x86_64 | amd64 | aarch64 | arm64) ok "Processor architecture: $arch. Every image exists for it." ;;
    *) failed "Processor architecture '$arch' is not supported. The images exist for amd64 and arm64 only." ;;
  esac
}

check_memory() {
  local bytes gib
  bytes="$(docker info --format '{{.MemTotal}}' 2>/dev/null)"
  gib="$(awk -v b="$bytes" 'BEGIN { printf "%.1f", b / 1073741824 }')"
  if awk -v g="$gib" -v min="$MIN_MEMORY_GIB" 'BEGIN { exit !(g >= min - 0.3) }'; then
    ok "Memory available to Docker: $gib GB."
  else
    failed "Docker can use only $gib GB of memory. The workshop needs $MIN_MEMORY_GIB GB. Give Docker more memory in its settings."
  fi
}

check_disk() {
  local free_kib gib
  if ! free_kib="$(docker run --rm "$DISK_PROBE_IMAGE" df -Pk / 2>/dev/null | awk 'NR == 2 { print $4 }')" || [[ -z "$free_kib" ]]; then
    note "The free disk space of Docker could not be measured. Make sure $MIN_DISK_GIB GB are free."
    return
  fi
  gib="$(awk -v k="$free_kib" 'BEGIN { printf "%.0f", k / 1048576 }')"
  if ((gib >= MIN_DISK_GIB)); then
    ok "Free disk space for Docker: $gib GB."
  else
    failed "Docker has only $gib GB of free disk space. The workshop needs $MIN_DISK_GIB GB. Free some space: docker system prune"
  fi
}

# Free MB and file system of the disk holding a folder (the nearest existing parent).
free_space() {
  local dir="$1"
  while [[ ! -d "$dir" ]]; do dir="$(dirname "$dir")"; done
  df -Pk "$dir" 2>/dev/null | awk 'NR == 2 { printf "%d %s\n", $4 / 1024, $1 }'
}

check_local_disk() {
  local folder_free folder_fs home_free home_fs need
  read -r folder_free folder_fs < <(free_space "$ROOT_DIR/..")
  if [[ -z "$folder_free" ]]; then
    note "The free disk space of this computer could not be measured. Make sure 1 GB is free, outside Docker."
    return
  fi
  need="$WORKSHOP_FOLDER_MB"
  if (($(java_major) >= 8)); then
    read -r home_free home_fs < <(free_space "$HOME")
    if [[ "$home_fs" == "$folder_fs" ]]; then
      need=$((need + GRADLE_HOME_MB))
    elif ((home_free < GRADLE_HOME_MB)); then
      failed "Your home folder has only $home_free MB free. Gradle needs $GRADLE_HOME_MB MB there, in .gradle."
    fi
  fi
  if ((folder_free >= need)); then
    ok "Free disk space outside Docker: $((folder_free / 1024)) GB (the workshop needs up to $(awk -v m="$need" 'BEGIN { printf "%.1f", m / 1024 }') GB here)."
  else
    failed "Only $folder_free MB free outside Docker, next to this folder. The workshop needs $need MB there."
  fi
}

# A port is busy when something answers on it.
check_ports() {
  local port busy=()
  for port in "${PORTS[@]}"; do
    if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
      busy+=("$port")
    fi
  done
  if ((${#busy[@]} == 0)); then
    ok "The ports of the sandbox are free: ${PORTS[*]}."
  else
    failed "These ports are used by another program: ${busy[*]}. Stop that program before the workshop."
  fi
}

check_servers() {
  if ! command -v curl >/dev/null 2>&1; then
    note "curl is not installed: the connection to the download servers was not checked."
    return
  fi
  local entry url name code
  for entry in "${SERVERS[@]}"; do
    url="${entry%%|*}"
    name="${entry#*|}"
    code="$(curl -sS -o /dev/null --max-time 15 -w '%{http_code}' "$url" 2>/dev/null)"
    if [[ -n "$code" && "$code" != 000 ]]; then
      ok "Can reach $name."
    else
      failed "Cannot reach $name ($url). Check your network, proxy or firewall."
    fi
  done
}

# Windows only, in Git Bash or WSL2: the workshop needs PowerShell next to Bash.
running_on_windows() {
  case "$(uname -s)" in
    MINGW* | MSYS* | CYGWIN*) return 0 ;;
  esac
  grep -qi microsoft /proc/version 2>/dev/null
}

check_powershell() {
  running_on_windows || return 0
  local shell version
  for shell in pwsh pwsh.exe powershell.exe powershell; do
    command -v "$shell" >/dev/null 2>&1 || continue
    version="$("$shell" -NoProfile -NonInteractive -Command '$PSVersionTable.PSVersion.ToString()' 2>/dev/null | tr -d '\r')"
    if [[ -n "$version" ]]; then
      ok "PowerShell $version is installed ($shell)."
      return 0
    fi
  done
  failed "PowerShell is not found. Install it: https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows"
}

check_java() {
  local major
  major="$(java_major)"
  if ((major >= 8)); then
    ok "Java $major is installed. Gradle will run on this computer."
  else
    ok "No Java installed. That is fine: Gradle will run in a container."
  fi
}

main() {
  title "Checking this computer"
  if check_docker; then
    check_architecture
    check_memory
    check_disk
  fi
  check_local_disk
  check_ports
  check_servers
  check_powershell
  check_java

  info ""
  if ((FAILURES == 0)); then
    info "${GREEN}This computer is ready for the workshop.${RESET}"
  else
    info "${RED}$FAILURES problem(s) to fix before the workshop.${RESET} Fix them, then run this check again."
    info "If you need help, write to $CONTACT."
  fi
  ((FAILURES == 0))
}

main "$@"
