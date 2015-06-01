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

# help message
function HELP {
  echo -e "Use:\n\t$PHASES_SCRIPT [-[lh]] <phase1,phase2,...> <script.sh> [arguments]"
  exit
}

if [ "$#" == 0 ]; then
  HELP
fi

# commandline option processing
# options to implement: verbose, debug, save resulting script
while getopts "l:h" opt; do
  case $opt in
    l)
      grep -n '^#phase ' "$OPTARG" | nl -b a
      ;;
    h)
      HELP
      ;;
  esac
done

# parse list of pases into an array
PHASE_LIST=${@:$OPTIND:1}
PHASES=(${PHASE_LIST//,/ })
echo $PHASE_LIST
echo ${PHASES[0]} - ${PHASES[1]}

# make sure that the target script exists
TGT_SCRIPT=${@:$OPTIND+1:1}
if [[ ! -x "$TGT_SCRIPT" ]]; then
  echo "File $TGT_SCRIPT is not executable or does not exists"
  exit 2
fi

# collect remaining arguments

# create a script in temporary directory

# execute resulting script

# Cleanup
rm -fr "$PHASES_TMPDIR"
