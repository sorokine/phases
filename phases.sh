#!/usr/bin/env bash
#
# phases script
#

# exit on errors
#set -e

# create temporary directory
PHASES_SCRIPT=$(basename ${BASH_SOURCE[0]})
PHASES_TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'phases')
if [[ -z "$PHASES_TMPDIR" ]]; then
  echo "Unable to create temporary directory $PHASES_TMPDIR" >&2
  exit 1
fi

# program names and misc. functions
# some program names depend upon the OS
SED=sed
GREP=grep
HEAD=head
TOUCH=touch
case "$OSTYPE" in
  darwin*)
    SED=gsed
    HEAD=ghead
    ;;
  *)
    ;;
esac

REAL_TAB=$(echo -e "\t")
contains () { # from http://stackoverflow.com/questions/14366390/bash-if-condition-check-if-element-is-present-in-array
  local array="$1[@]"
  local seeking=$2
  local in=0
  for element in "${!array}"; do
      if [[ "$element" == "$seeking" ]]; then
          in=1
          break
      fi
  done
  echo $in
}

# help message
function print_help {
  echo -e "Use:\n\t$PHASES_SCRIPT [-h|--help] | [[-s|--skip] <phase1,phase2,...> <script.sh> [script_arguments]] | [-l|--list <script.sh>]"
  echo
  echo -e "\t-l|--list <script>\tlist phases in the script"
  echo -e "\t-h|--help\tthis help"
  echo -e "\t-s|--skip\tskip the phases in the list, run everything else"
  echo -e "\t-v|--verbose\tincrease verbosity, use more v to be more verbose"
  exit
}

if [ "$#" == 0 ]; then
  echo ERROR: no arguments
  print_help
fi

# commandline option processing
# options to implement: verbose, debug, save resulting script
v=0 # verbosity level
skip=0 # treat the list of phases as include list (0) or skip list (1)
while :; do
  case $1 in
    -h|--help)
      print_help
      ;;
    -v|--verbose)
      # verbosity level
      ((v++))
      ;;
    -l|--list)
      if [ "$#" != 2 ]; then
        echo wrong number of arguments
        print_help
      else
        echo "$(printf 'phase#\tline\tname')"
        ${GREP} -n '^#phase ' "$OPTARG" | ${SED} -e "s/:#phase /$REAL_TAB/" | nl -b a
        exit
      fi
      ;;
    -s|--skip)
      skip=1
      ;;
      # TODO: nocleanup version
    -?*)
      printf 'ERROR: Unknown option: %s\n' "$1" >&2
      print_help
      ;;
    *)
      break;
      ;;
  esac

  shift
done

# make sure that the target script exists
TGT_SCRIPT="$2"
if [[ ! -x "$TGT_SCRIPT" ]]; then
  echo "File $TGT_SCRIPT is not executable or does not exists" >&2
  exit 2
fi

# name of the preprocessed script
SCR_BASENAME=$(basename "$TGT_SCRIPT")
PHASED_SCRIPT="$PHASES_TMPDIR/$SCR_BASENAME"
echo Temporary script name: ${PHASED_SCRIPT}

# parse list of pases into arrays of skipped and used phases
declare -a USE_PHASES=()
declare -a SKIP_PHASES=()
for phase in ${1//,/ }; do
  if [[ "$skip" == 0 ]]; then
    if [[ "$phase" == ^* ]]; then
      SKIP_PHASES+=("${phase#^}")
    else
      USE_PHASES+=("$phase")
    fi
  else
    [[ "$phase" != ^* ]] && SKIP_PHASES+=("$phase")
  fi
done
echo use phases: "${USE_PHASES[@]}"
echo skip phases: "${SKIP_PHASES[@]}"

# load list of phases from the target script and add phase 'init'
mapfile -t ALL_PHASES < <(${SED} -n "s/^#phase // p" "$TGT_SCRIPT")
ALL_PHASES=('init' ${ALL_PHASES[@]})
echo phases from the script: "${ALL_PHASES[@]}"

# verify that there are no syntax errors in the phases list
for phase in ${1//,/ }; do
  if [[ $(contains ALL_PHASES "${phase#^}") == 0 ]]; then
    echo ERROR: Phase $phase not contained in $TGT_SCRIPT >&2
    exit 3
  fi
done

# make sure that the same phase is not listed both as use and skip
for phase in "${SKIP_PHASES[@]}"; do
  if [[ $(contains USE_PHASES "${phase}") == 1 ]]; then
    echo ERROR: Phase $phase both included and skipped: $1 >&2
    exit 4
  fi
done

# compile the list of phases that will be executed
declare -a EXEC_PHASES=()
for phase in "${ALL_PHASES[@]}"; do
  if [[ $(contains SKIP_PHASES "$phase") == 0 ]]; then
    if [[ "$skip" == 0 ]]; then
      [[ "$phase" == 'init' || $(contains USE_PHASES "$phase") == 1 ]] && \
        EXEC_PHASES+=("$phase")
      else
        EXEC_PHASES+=("$phase")
    fi
  fi
done
echo exec phases: "${EXEC_PHASES[@]}"

# create a script in temporary directory
${TOUCH} "$PHASED_SCRIPT"

## extract preamble
if [[ "${EXEC_PHASES[0]}" == 'init' ]]; then
  echo Extracting phase init
  ${SED} -n "1,/^#phase / p" < "$TGT_SCRIPT" | ${HEAD} -n -1 >> "$PHASED_SCRIPT"
  echo -e "echo !!! end of implied phase init !!!\necho\n" >> "$PHASED_SCRIPT"
fi

## extract remaining phases
for phase in "${EXEC_PHASES[@]}"; do
  if [[ "$phase" != 'init' ]]; then # skip phase init that already has been processed
    echo Extracting phase $phase
    echo -e "echo !!! start of phase $phase !!!" >> "$PHASED_SCRIPT"
    ${SED} -n "/^#phase $phase/,/^#phase / p" < "$TGT_SCRIPT" | ${HEAD} -n -1 >> "$PHASED_SCRIPT"
    echo -e "echo !!! end of phase $phase !!!\necho\n" >> "$PHASED_SCRIPT"
  fi
done

# execute phased script
echo
echo "!!! executing phased script !!!"
chmod +x "$PHASED_SCRIPT"
"$PHASED_SCRIPT" "${@:3}"
excode=$?
echo "!!! Phased script completed with code $excode !!!"

# Cleanup
# TODO: cleanup on signal
rm -fr "$PHASES_TMPDIR"

exit $excode
