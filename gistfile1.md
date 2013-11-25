Rather often it is neccesary to execute different parts of a bash script and be able to choose which phases of a bach script has to be executed.  Use cases: long installation scripts, generation of database structures.

This is a way to easily throw a command language on top of an existing script.

ideas for implementaion:

```phases init,load,dump myscript.sh opt1 opt2 opt3```

or by loading a library in the script

```myscript.sh phases=init,load,dump opt1 opt2 opt3```

the script has to load phases library first

implementaion options
 * preprocessor
 * script

inside the script commands should be called as

```phase init some_command ....```

OR

boundaries of phases should be put inside comments, e.g. ```#phase init``` 
 * needs syntax checker
 * subphasez can be implemented using multiple #

idea for the name *phazes*

it should be possible to
 * specify which phases to run or skip either as a list or as interval or both
 * be able to say 'run the rest' or 'skip the rest'
 * conditional runs or skips of phases
 * commands until the 1st mentioned phase are considered ```_init``` and commands after the last phase called ```_end```
 * see a list phases in a script
 * reporting of phase execution
 * facility for logging
  * log results of all commands from currrent run seprately into .err and .out files
  * a log with all script runs with timer, working directory variable values
 * ability to restart from the point it failed on previous run
 * properly handle ^C and other signals
 * record the results of earlier runs (create .phazes directory?)
 * check if variables set in the skipped phase are used in the later executed phases
 * what do I do with shebang?

motivation
 * if implemented with standard bash facilities the script becomes long and it is hard to grasp how it works
 * 
 
somewhat similar projects
 * https://github.com/dymatic/bpp/blob/master/bpp/sample.bpp