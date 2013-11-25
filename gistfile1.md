Rather often it is neccesary to execute different parts of a bash script and be able to choose which phases of a bach script has to be executed.  Use cases: long installation scripts, generation of database structures.

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
 * commands until the 1st mentioned phase are considered _init and commands after the last phase called _end
 * see a list phases in a script
 * reporting of phase execution
 * facility for logging
 * ability to restart from the point it failed on previous run
 * properly handle ^C and other signals
