#!/usr/bin/env bash
#
# phases script
#

# exit on errors
set -e

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
TAIL=tail
TR=tr
case "$OSTYPE" in
  darwin*)
    SED=gsed
    HEAD=ghead
    TAIL=gtail
    TR=gtr
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
  return "$in"
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

# parse list of pases into an array
declare -a PHASES=( "${1//,/ }" )

# make sure that the target script exists
TGT_SCRIPT="$2"
if [[ ! -x "$TGT_SCRIPT" ]]; then
  echo "File $TGT_SCRIPT is not executable or does not exists"
  exit 2
fi

# name of the preprocessed script
SCR_BASENAME=$(basename "$TGT_SCRIPT")
PHASED_SCRIPT="$PHASES_TMPDIR/$SCR_BASENAME"
echo Temporary script name: ${PHASED_SCRIPT}

# create a script in temporary directory
## extract preamble
echo Extracting phase init
${SED} -n "1,/^#phase / p" < "$TGT_SCRIPT" | ${HEAD} -n -1 > "$PHASED_SCRIPT"
echo -e "echo !!! end of implied phase init !!!\necho\n" >> "$PHASED_SCRIPT"
## extract remaining phases
if [[ -z "$skip" ]]; then
  # use only listed phases
  echo "Phases to be executed:" "${PHASES[@]:0}"
  for phase in "${PHASES[@]}"; do
    echo Extracting phase $phase
    echo -e "echo !!! start of phase $phase !!!" >> "$PHASED_SCRIPT"
    ${SED} -n "/^#phase $phase/,/^#phase / p" < "$TGT_SCRIPT" | ${HEAD} -n -1 >> "$PHASED_SCRIPT"
    echo -e "echo !!! end of phase $phase !!!\necho\n" >> "$PHASED_SCRIPT"
  done
else
  # skip phases in the list
  mapfile -t ALL_PHASES < <(${SED} -n "s/^#phase // p" "$TGT_SCRIPT")
  echo "Skipping phases '" "${PHASES[@]}" "' from all phases: '" "${ALL_PHASES[@]}" "'"
  for phase in "${ALL_PHASES[@]}"; do
    echo "$phase : " $(contains PHASES "$phase")
    contains PHASES "$phase"
    if [[ $? == 1 ]]; then
      echo Skipping phase $phase
      echo -e "echo !!! skipped phase $phase !!!" >> "$PHASED_SCRIPT"
    else
      echo Extracting phase $phase
      echo -e "echo !!! start of phase $phase !!!" >> "$PHASED_SCRIPT"
      ${SED} -n "/^#phase $phase/,/^#phase / p" < "$TGT_SCRIPT" | ${HEAD} -n -1 >> "$PHASED_SCRIPT"
      echo -e "echo !!! end of phase $phase !!!\necho\n" >> "$PHASED_SCRIPT"
    fi
  done
fi

# execute phased script
echo
echo "!!! executing phased script !!!"
chmod +x "$PHASED_SCRIPT"
"$PHASED_SCRIPT" "${@:$(( OPTIND + 2 ))}"
excode=$?
echo "!!! Phased script completed with code $excode !!!"

# Cleanup
# TODO: cleanup on signal
rm -fr "$PHASES_TMPDIR"

exit $excode
