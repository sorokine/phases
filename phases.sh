#!/usr/bin/env bash
#
# phases script
#

# set variables
PHASES_SCRIPT=$(basename ${BASH_SOURCE[0]})
PHASES_TMPDIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'phases')
if [[ -z "$PHASES_TMPDIR" ]]; then
  echo "Unable to create temporary directory $PHASES_TMPDIR" >&2
  exit 1
fi

# program names and misc. functions
# set depending on the OS
SED=sed
GREP=grep
HEAD=head
TAIL=tail
TR=tr
case "$OSTYPE" in
  darwin* )
    SED=gsed
    HEAD=ghead
    TAIL=gtail
    TR=gtr
    ;;
  * )
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
function HELP {
  echo -e "Use:\n\t$PHASES_SCRIPT -h | [-s] <phase1,phase2,...> <script.sh> [script_arguments] | -l <script.sh>"
  echo
  echo -e "\t-l <script>\tlist phases in the script"
  echo -e "\t-h\tthis help"
  exit
}

if [ "$#" == 0 ]; then
  echo no arguments
  HELP
fi

# commandline option processing
# options to implement: verbose, debug, save resulting script
while getopts "l:hs" opt; do
  case $opt in
    l)
      if [ "$#" != 2 ]; then
        echo wrong number pf arguments
        HELP
      else
        echo "$(printf 'phase#\tline\tname')"
        ${GREP} -n '^#phase ' "$OPTARG" | ${SED} -e "s/:#phase /$REAL_TAB/" | nl -b a
        exit
      fi
      ;;
    s)
      skip=1
      ;;
      # TODO: verbosity option
      # TODO: nocleanup version
    h)
      HELP
      ;;
  esac
done

# parse list of pases into an array
PHASE_LIST=(${@:$OPTIND:1})
PHASES=(${PHASE_LIST//,/ })

# make sure that the target script exists
TGT_SCRIPT="${@:$(( OPTIND + 1 )):1}"
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
