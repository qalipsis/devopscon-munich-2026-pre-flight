#!/usr/bin/env bash
# Prepares this computer for the workshop "From Green Build to Broken Peak" (DevOpsCon Munich 2026).
#
#   ./preflight.sh                  step by step: you decide before each step
#   ./preflight.sh --yes            every step without asking (the terms still need --accept-terms)
#   ./preflight.sh --accept-terms   accept the terms of the workshop images without being asked
#
# Every step is also a script of its own in scripts/, which you can run again at any time.
# The output is also written to preflight.log.
set -uo pipefail
# shellcheck source=scripts/lib.sh
source "$(dirname "$0")/scripts/lib.sh"

# Measured on a clean computer; see README.md.
IMAGES_DISK="about 8 GB"
GRADLE_DISK="up to 1 GB"

ASSUME_YES=false
ACCEPT_TERMS=false
TERMS_ACCEPTED=false
STEP_NAMES=()
STEP_RESULTS=()
TOTAL_STEPS=5
CURRENT_STEP=0

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

parse_args() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --yes | -y) ASSUME_YES=true ;;
      --accept-terms) ACCEPT_TERMS=true ;;
      --help | -h) usage ;;
      *) die "Unknown option '$arg'. Use --help to see the options." ;;
    esac
  done
  if [[ "$ASSUME_YES" == false && ! -t 0 ]]; then
    die "This script asks questions, but it cannot read your answers here. Run it in a terminal, or add --yes."
  fi
}

# Prints one block of the explanation of a step, indented.
explain() {
  local label="$1" text="$2"
  printf '  %s%-9s%s %s\n' "$BOLD" "$label" "$RESET" "$text"
}

# Shows the step and asks what to do. Returns 0 to run it, 1 to skip it. Stops the script on "q".
start_step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  STEP_NAMES+=("$1")
  printf '\n%s======== Step %d of %d: %s ========%s\n\n' "$BOLD" "$CURRENT_STEP" "$TOTAL_STEPS" "$1" "$RESET"
}

confirm_step() {
  info ""
  [[ "$ASSUME_YES" == true ]] && return 0
  local answer
  while true; do
    printf 'Press %sEnter%s to run this step, %ss%s to skip it, %sq%s to stop here: ' \
      "$BOLD" "$RESET" "$BOLD" "$RESET" "$BOLD" "$RESET"
    read -r answer || answer=q
    case "$answer" in
      "") return 0 ;;
      s | S) return 1 ;;
      q | Q) finish "stopped" ;;
      *) info "Please type nothing (just Enter), s or q." ;;
    esac
  done
}

record() { STEP_RESULTS+=("$1"); }

# Runs a step script and records how it ended.
run_step() {
  if "$@"; then
    record "done"
  else
    record failed
    info ""
    warn "This step did not end well. Read the messages above."
    [[ "$ASSUME_YES" == true ]] && return
    local answer
    printf 'Press %sEnter%s to continue with the next step, %sq%s to stop here: ' "$BOLD" "$RESET" "$BOLD" "$RESET"
    read -r answer || answer=q
    [[ "$answer" == q || "$answer" == Q ]] && finish "stopped"
  fi
}

step_check() {
  start_step "Check your computer"
  explain "Why" "The workshop runs everything on your computer, in Docker. This step finds problems"
  explain "" "now, at home, where you have time to fix them, and not in the room."
  explain "What" "It checks Docker, Docker Compose, the memory and disk space of Docker, the disk space"
  explain "" "outside Docker, the network ports the workshop uses, the connection to the servers"
  explain "" "of the next steps and, on Windows, PowerShell."
  explain "For you" "Nothing is installed and nothing is changed. Only one very small image (busybox,"
  explain "" "about 2 MB) is downloaded, to measure the free disk space."
  if confirm_step; then run_step "$ROOT_DIR/scripts/check.sh"; else record skipped; fi
}

step_terms() {
  start_step "Terms of the workshop images"
  explain "Why" "Three images of the workshop are the system you will test. They are not open source:"
  explain "" "AERIS IT Solutions GmbH lends them to you, free of charge, for this workshop only."
  explain "What" "This step shows the main points of the terms. The full text is in README.md,"
  explain "" "section \"Terms of the workshop images\". Please read it before you answer."
  explain "For you" "If you accept, the next step downloads these three images. If you do not accept,"
  explain "" "they are not downloaded, and you cannot do the exercises of the workshop with them."
  info ""
  info "  The main points:"
  info "   - You may use the images only to prepare for, attend and do the exercises of this workshop."
  info "   - You may not give them to anybody, publish them, or copy them to another registry."
  info "   - You may not use them in production or for commercial purposes."
  info "   - AERIS may withdraw them at any time. Delete them when you do not need them anymore."
  info "   - Austrian law applies. The open-source parts inside keep their own licences."
  info ""
  if [[ "$ACCEPT_TERMS" == true ]]; then
    info "You accepted the terms with the option --accept-terms."
    TERMS_ACCEPTED=true
    record accepted
    return
  fi
  if [[ "$ASSUME_YES" == true ]]; then
    info "Not accepted: --yes does not accept the terms. Add --accept-terms to accept them."
    record "not accepted"
    return
  fi
  local answer
  while true; do
    printf 'Do you accept these terms? Type %syes%s or %sno%s: ' "$BOLD" "$RESET" "$BOLD" "$RESET"
    read -r answer || answer=no
    case "$answer" in
      yes | YES | Yes) TERMS_ACCEPTED=true; record accepted; return ;;
      no | NO | No) record "not accepted"; return ;;
      *) info "Please type the whole word: yes or no." ;;
    esac
  done
}

step_pull() {
  start_step "Download the images"
  local total platform count
  total="$(images_of sandbox; images_of pipeline; images_of platform)"
  total="$(grep -c . <<<"$total")"
  platform="$(images_of platform | grep -c .)"
  count="$total"
  [[ "$TERMS_ACCEPTED" == true ]] || count=$((total - platform))
  explain "Why" "The workshop uses $total container images, $IMAGES_DISK in total. In the room,"
  explain "" "everybody shares one network, which is slow. At home it takes minutes; in the room,"
  explain "" "it can take most of the first exercise."
  if [[ "$TERMS_ACCEPTED" == true ]]; then
    explain "What" "It downloads the $count images listed in images.lock with \"docker pull\". Among them is act,"
  else
    explain "Note" "You did not accept the terms: the $platform workshop platform images are left out, and"
    explain "" "without them you cannot do the exercises. To get them later, accept the terms with:"
    explain "" "  scripts/pull.sh --accept-terms"
    explain "What" "It downloads the other $count images of images.lock with \"docker pull\". Among them is act,"
  fi
  explain "" "the tool that runs GitHub workflows on your computer at the end of the workshop."
  explain "For you" "Docker uses $IMAGES_DISK of disk space more. After the workshop, you can"
  explain "" "delete the images: see README.md, section \"After the workshop\"."
  if confirm_step; then
    if [[ "$TERMS_ACCEPTED" == true ]]; then
      run_step "$ROOT_DIR/scripts/pull.sh" --accept-terms
    else
      run_step "$ROOT_DIR/scripts/pull.sh"
    fi
  else
    record skipped
  fi
}

step_gradle() {
  start_step "Prepare Gradle"
  explain "Why" "In the workshop, Gradle compiles and runs the test scenarios in a Java container"
  explain "" "($GRADLE_IMAGE). You do not need Java on your computer: if you have none, do not"
  explain "" "install it. The first build downloads Gradle and the QALIPSIS libraries: $GRADLE_DISK."
  explain "What" "It builds a small project that uses exactly the same tools and libraries, in the"
  explain "" "same container as on the day."
  explain "For you" "The files go to the Docker volume $GRADLE_CACHE_VOLUME ($GRADLE_DISK)."
  if (($(java_major) >= 8)); then
    explain "" "You have Java $(java_major): Gradle and Java 21 are also downloaded into the folder"
    explain "" ".gradle of your home folder (about 400 MB), for Gradle on your own computer. Java 21"
    explain "" "is not installed for the rest of your computer."
  fi
  if confirm_step; then run_step "$ROOT_DIR/scripts/warmup.sh"; else record skipped; fi
}

step_clone() {
  start_step "Get the workshop repository"
  explain "Why" "On the day, everything starts from this repository. Downloaded now, you are ready"
  explain "" "the moment the workshop begins."
  explain "What" "It downloads the workshop repository next to this folder, on its start branch."
  explain "" "If it is not published yet, it says so: run scripts/clone.sh again on the day."
  explain "For you" "A folder devopscon-munich-2026 next to this one, a few MB."
  if confirm_step; then run_step "$ROOT_DIR/scripts/clone.sh"; else record skipped; fi
}

finish() {
  local how="${1:-completed}" index
  printf '\n%s======== Summary ========%s\n\n' "$BOLD" "$RESET"
  for index in "${!STEP_NAMES[@]}"; do
    printf '  %-32s %s\n' "${STEP_NAMES[index]}" "${STEP_RESULTS[index]:-stopped}"
  done
  info ""
  if [[ "$how" == stopped ]]; then
    info "You stopped the preparation. Start ./preflight.sh again whenever you want."
  elif [[ " ${STEP_RESULTS[*]} " == *" failed "* || " ${STEP_RESULTS[*]} " == *" skipped "* ]]; then
    info "Some steps were skipped or failed. Run ./preflight.sh again before the workshop."
  elif [[ "$TERMS_ACCEPTED" == false ]]; then
    info "Everything is ready, except the three workshop platform images, whose terms you did not accept."
    info "Without them you cannot do the exercises. To get them: scripts/pull.sh --accept-terms"
  else
    info "${GREEN}Your computer is ready for the workshop.${RESET} Keep the images until the workshop."
  fi
  info ""
  info "Questions, before or after the workshop: $CONTACT"
  info "Please attach the file preflight.log to your message: it shows what happened here."
  exit 0
}

main() {
  parse_args "$@"
  exec > >(tee "$ROOT_DIR/preflight.log") 2>&1

  printf '%sPreparing your computer for the workshop "From Green Build to Broken Peak"%s\n' "$BOLD" "$RESET"
  info "DevOpsCon Munich 2026"
  info ""
  info "This takes 10 to 30 minutes, depending on your network. The workshop needs 15 GB free inside Docker"
  info "(about 9 GB are downloaded now) and up to 1 GB outside Docker, next to this folder."
  info "There are $TOTAL_STEPS steps. Before each step, you read why it is needed and what it does,"
  info "and you decide: run it, skip it, or stop. You can start this script again at any time."

  step_check
  step_terms
  step_pull
  step_gradle
  step_clone
  finish
}

main "$@"
