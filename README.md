# phases
## Simple Minimally Invasive bash Preprocessor

The idea is to split a bash script into phases and the executed
only selected phases from the script.  This taks is often needed
in the tasks like loading data into the database or similar.

## Prepare your bash script

Split your bash script into phases by inserting ```#phase```
followed by the phase name at the begining of the line that
separate parts of the script.  

Do not load files relative to script location

## Usage

Run your script as

  phases.sh

## Phase list

In skip mode negated phases (```^init```) are simply ignored.

The order of phases in the list does not matter and the sequence phases will always be preserved as in the original script.
