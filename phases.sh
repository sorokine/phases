#!/usr/bin/env bash
#
# phases script
#

# exit on errors
#set -e

# TODO: be able to override incl/excl phases (phase that is mentioned later gets a precedent)
# TODO: phase list consistency checks: warn on duplicates and illegal symbols
# TODO: specify phases by sequence numbers
# TODO: verify that error handling in the phased scripts properly works
# TODO: execution of phases in subshell

# create temporary directory
PHASES_SCRIPT=$(basename ${BASH_SOURCE[0]})

# OS-dependent program names
SED=sed
GREP=grep
HEAD=head
case "$OSTYPE" in
  darwin*)
    SED=gsed
    HEAD=ghead
    ;;
  *)
    ;;
esac

# utility functions
REAL_TAB=$(echo -e "\t")

function contains () { # modified from http://stackoverflow.com/questions/14366390/bash-if-condition-check-if-element-is-present-in-array
  # the function echoes -1 if the element is not found or its index otherwise
  local array="$1[@]"
  local seeking=$2
  local in=-1
  local i=0
  for element in "${!array}"; do
    if [[ "$element" == "$seeking" ]]; then
      in=$i
      break
    fi
    ((i++))
  done
  echo $in
}

# help message
function print_help {
  echo -e "Use:\n\t$PHASES_SCRIPT [-h|--help] | [[-s|--skip] [--] <^init,phase1,[phase2]-[phase4],...> <script.sh> [script_arguments]] | [-l|--list <script.sh>]"
  echo
  echo -e "\t-l|--list <script>\tlist phases in the script"
  echo -e "\t-h|--help\tthis help"
  echo -e "\t-s|--skip\tskip the phases in the list, run everything else"
  echo -e "\t-v|--verbose\tincrease verbosity, use more v to be more verbose"
  echo -e "\t-n|--noclean\t do not remove temporary directory when finished"
  echo -e "\t-o|--output=<file>\tsave resulting script in a file, do not execute it"
  exit
}

if [ "$#" == 0 ]; then
  echo ERROR: no arguments
  print_help
fi

# variables from command-line options
v=0 # verbosity level
skip=0 # treat the list of phases as include list (0) or skip list (1)
clean=1 # perform cleanup

# command line option processing
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
      if [ "$#" -lt 2 ]; then
        echo wrong number of arguments
        print_help
      else
        [[ "$#" -gt 2 ]] && echo Arguments after $2 ignored
        printf 'phase#\tline\tname\n'
        ( printf '0\tinit\n'; ${GREP} -n '^#phase ' "$2" | ${SED} -e "s/:#phase /$REAL_TAB/" ) | nl -b a -v 0
        exit
      fi
      ;;
    -s|--skip)
      skip=1
      ;;
    -n|--noclean)
      clean=0
      ;;
    -o|--output)
      if [ -n "$2" ]; then
        outp_scr="$2"
        shift 2
        continue
      else
        printf 'ERROR: "--output" requires a non-empty option argument.\n' >&2
        exit 1
      fi
      ;;
    --output=?*)
      outp_scr=${1#*=}
      ;;
    --output=)         # Handle the case of an empty --output=
      printf 'ERROR: "--output" requires a non-empty option argument.\n' >&2
      exit 1
      ;;
    --)
      shift
      break
      ;;
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

((v>0)) && echo Verbosity set to $v
((v>1)) && echo Using programs: SED=$SED GREP=$GREP HEAD=$HEAD

# make sure that the target script exists
TGT_SCRIPT="$2"
SCR_BASENAME=$(basename "$TGT_SCRIPT")
if [[ ! -x "$TGT_SCRIPT" ]]; then
  echo "File $TGT_SCRIPT is not executable or does not exists" >&2
  exit 2
fi

# create temporary directory
PHASES_TMPDIR=$(mktemp -d -t "phased-$SCR_BASENAME.XXXXXX")
if [[ -z "$PHASES_TMPDIR" ]]; then
  echo "Unable to create temporary directory $PHASES_TMPDIR" >&2
  exit 1
fi
((v>0)) && echo Temporary working directory set to $PHASES_TMPDIR
((clean==0)) && echo Temporary files will be preserved in $PHASES_TMPDIR

# cleanup function
function cleanup() {
  if [[ $clean == 1 && -e "$PHASES_TMPDIR" ]]; then
    rm -fr "$PHASES_TMPDIR"
    ((v>0)) && echo Removing temporary working directory $PHASES_TMPDIR
  fi
}

trap cleanup EXIT

# name of the preprocessed script
PHASED_SCRIPT="$PHASES_TMPDIR/$SCR_BASENAME"
((v>0)) && echo Output script name: ${PHASED_SCRIPT}

# load list of phases from the target script and add phase 'init'
mapfile -t ALL_PHASES < <(${SED} -n "s/^#phase // p" "$TGT_SCRIPT")
ALL_PHASES=('init' ${ALL_PHASES[@]})
((v>0)) && echo Phases loaded from the script $TGT_SCRIPT: "${ALL_PHASES[@]}"

# expand ranges of phases
declare -a PHASE_LIST=()
for phase in ${1//,/ }; do
  if [[ $phase = *-* ]]; then

    # save negation
    if [[ $phase == ^* ]]; then
      neg='^'
      phase="${phase#^}"
    else
      neg=''
    fi

    # prohibited interval with two open ends
    if [[ $phase == -*- ]]; then
      printf "ERROR: malformed interval %s\n" "$phase" >&2
      exit 8
    fi

    # interval with open left end, assign to the 0th element
    [[ ${phase:0:1} == '-' ]] && \
      i0=0 || i0=$(contains ALL_PHASES "${phase%%-*}")
    # interval with open right end, assign to the last elemenet
    [[ ${phase: -1} == '-' ]] && \
      i1=$((${#ALL_PHASES[@]}-1)) || i1=$(contains ALL_PHASES "${phase##*-}")
    ((v>1)) && echo Range $phase indices $i0 $i1

    if (( i0 < 0 || i1 < 0 || i0 >= i1 )); then
      printf "ERROR: wrong phase range %s (%s-%s)\n" "$neg$phase" $i0 $i1 >&2
      exit 6
    fi

    for ph in "${ALL_PHASES[@]:$i0:((i1-i0+1))}"; do
      PHASE_LIST+=($neg"$ph")
    done
  else
    # verify that there are no syntax errors in the phases list
    if [[ $(contains ALL_PHASES "${phase#^}") == "-1" ]]; then
      echo ERROR: Phase \'$phase\' not contained in $TGT_SCRIPT >&2
      exit 3
    else
      PHASE_LIST+=("$phase")
    fi
  fi
done
((v>0)) && echo Expanded phase list: "${PHASE_LIST[@]}"

# parse list of phases into arrays of skipped and used phases
declare -a USE_PHASES=()
declare -a SKIP_PHASES=()
for phase in "${PHASE_LIST[@]}"; do
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
((v>0)) && echo Use phases: "${USE_PHASES[@]}"
((v>0)) && echo Skip phases: "${SKIP_PHASES[@]}"

# make sure that the same phase is not listed both as use and skip
for phase in "${SKIP_PHASES[@]}"; do
  if [[ $(contains USE_PHASES "${phase}") -ge 0 ]]; then
    echo ERROR: Phase \'$phase\' both included and skipped: $1 >&2
    exit 4
  fi
done

# compile the list of phases that will be executed
declare -a EXEC_PHASES=()
for phase in "${ALL_PHASES[@]}"; do
  if [[ $(contains SKIP_PHASES "$phase") == -1 ]]; then
    if [[ "$skip" == 0 ]]; then
      [[ "$phase" == 'init' || $(contains USE_PHASES "$phase") -ge 0 ]] && \
        EXEC_PHASES+=("$phase")
      else
        EXEC_PHASES+=("$phase")
    fi
  fi
done
((v>0)) && echo Phases to be executed: "${EXEC_PHASES[@]}"

# create a script in temporary directory
echo > "$PHASED_SCRIPT"

## extract preamble
if [[ "${EXEC_PHASES[0]}" == 'init' ]]; then
  ((v>0)) && echo Extracting phase init
  ${SED} -n "1,/^#phase / p" < "$TGT_SCRIPT" | ${HEAD} -n -1 >> "$PHASED_SCRIPT"
  echo -e "echo !!! end of implied phase init !!!\necho\n" >> "$PHASED_SCRIPT"
else
  printf "echo !!! skipped phase: init !!! \n" >> "$PHASED_SCRIPT"
fi

## extract remaining phases
for phase in "${ALL_PHASES[@]}"; do
  [[ "$phase" == 'init' ]] && continue # skip phase init that already has been processed

  if [[ $(contains EXEC_PHASES "$phase") -ge 0 ]]; then
    ((v>0)) && echo Extracting phase $phase
    echo -e "echo !!! start of phase $phase !!!" >> "$PHASED_SCRIPT"
    if [[ "$phase" != "${ALL_PHASES[-1]}" ]]; then
      ${SED} -n "/^#phase $phase/,/^#phase / p" < "$TGT_SCRIPT" | ${HEAD} -n -1 >> "$PHASED_SCRIPT"
    else
      # keep all lines in the very last section
      ${SED} -n "/^#phase $phase/,\$p" < "$TGT_SCRIPT" >> "$PHASED_SCRIPT"
    fi
    echo -e "echo !!! end of phase $phase !!!\necho\n" >> "$PHASED_SCRIPT"
  else
    printf "echo !!! skipped phase: %s !!!\necho\n" "$phase" >> "$PHASED_SCRIPT"
  fi
done

# execute phased script
if [[ -n "$outp_scr" ]]; then
  echo Saving output script into: $outp_scr
  cp "$PHASED_SCRIPT" "$outp_scr"
else
  echo
  echo "!!! executing phased script !!!"
  chmod +x "$PHASED_SCRIPT"
  "$PHASED_SCRIPT" "${@:3}"
  excode=$?
  echo "!!! Phased script completed with code $excode !!!"

  exit $excode
fi
