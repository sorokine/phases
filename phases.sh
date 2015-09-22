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

# programss to use and other variables
SED=gsed
GREP=grep
HEAD=ghead
TAIL=gtail
REAL_TAB=$(echo -e "\t")

# help message
function HELP {
  echo -e "Use:\n\t$PHASES_SCRIPT -h | <phase1,phase2,...> <script.sh> [script_arguments] | -l <script.sh>"
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
while getopts "l:h" opt; do
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
    h)
      HELP
      ;;
  esac
done

# parse list of pases into an array
PHASE_LIST=(${@:$OPTIND:1})
PHASES=(${PHASE_LIST//,/ })
echo "Phases to be executed:" "${PHASES[@]:0}"

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

# collect remaining arguments

# create a script in temporary directory
## extract preamble
echo Extracting phase init
${SED} -n "1,/^#phase / p" < "$TGT_SCRIPT" | ${HEAD} -n -1 > "$PHASED_SCRIPT"
echo -e "echo !!! end of implied phase init !!!\necho\n" >> "$PHASED_SCRIPT"
## extract remaining phases
for phase in "${PHASES[@]}"; do
  echo Extracting phase $phase
  echo -e "echo !!! start of phase $phase !!!" >> "$PHASED_SCRIPT"
  ${SED} -n "/^#phase $phase/,/^#phase / p" < "$TGT_SCRIPT" | ${HEAD} -n -1 >> "$PHASED_SCRIPT"
  echo -e "echo !!! end of phase $phase !!!\necho\n" >> "$PHASED_SCRIPT"
done

# execute phased script
echo
echo "!!! executing phased script !!!"
chmod +x "$PHASED_SCRIPT"
"$PHASED_SCRIPT" "${@:$(( OPTIND + 2 ))}"

# Cleanup
#rm -fr "$PHASES_TMPDIR"
