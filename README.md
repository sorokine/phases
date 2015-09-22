# phases: Simple non-Invasive bash Preprocessor

The idea is to split a bash script into phases and the executed
only selected phases from the script.  This taks is often needed
in the tasks like loading data into the database or similar.

## Prepare your bash script

Split your bash script into phases by inserting ```#phase```
followed by the phase name at the begining of the line that
separate parts of the script.  

## Usage

Run your script as

  phases.sh 
