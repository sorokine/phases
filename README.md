# phases
## Minimally Invasive bash Preprocessor

I have to maintain several shell scripts that perform long but rather simple sequences of steps like loading data into a database or running a simulation model with pre- and post-processing.  Most o the scripts The idea is to split a bash script into phases and the executed
only selected phases from the script.  

## Prepare your bash script

Split your bash script into phases by inserting directive ```#phase```
followed by the phase name at the beginning of the line that
separate parts of the script.  

Do not load files relative to script location

## Usage

Run your script as

  phases.sh

## Phase list

In skip mode negated phases (```^init```) are simply ignored.

The order of phases in the list does not matter and the sequence phases will always be preserved as in the original script.
