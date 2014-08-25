Rather often it is neccesary to execute different parts of a bash script and be able to choose which phases of a bach script has to be executed.  Use cases: long installation scripts, generation of database structures.

This is a way to easily throw a command language on top of an existing script.

ideas for implementation:

```phases init,load,dump myscript.sh opt1 opt2 opt3```

or by loading a library in the script

```myscript.sh phases=init,load,dump opt1 opt2 opt3```

the script has to load phases library first

implementation options

 * preprocessor
     * the scripts can be run outside of phazes environmrnt without modification
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
 * to indicate a phase ti skip use caret ```^```
 * specify pahse either by name or by sequence
 * conditional runs or skips of phases
 * either-or phases
 * commands until the 1st mentioned phase are considered ```_init``` and commands after the last phase called ```_end``` (or _pre and _post?)
     * special phases are always executed unless explicitly excluded
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
 * warning for comments with no space after #
 * git-aware (as an option)
 * non-bash intepreters (LaTeX?, psql)
     * other comment character
     * library of supported interpreters
     * specific interpretor for each phase
          * can be specified through shebang option 
 * optional end of phase in the script ```#^phase [name]```
 * verbosity and logging levels (can be set seprately)
     * only errors
     * +phase names
     * +all stderr
     * +filtered stdout
     * +unfiltered stdout
 * most options can be specified for either command line or in #phase
 * \#phase should allow comments after # until the end of the line
 * subphases

motivation

 * if implemented with standard bash facilities the script becomes long and it is hard to grasp how it works
 * this is somewhat similar to Makefile, maven or ant but success counts and restarting can be rather tricky especially if you do not have clearly defined or local tragets like is the case with databases and installations
 
somewhat similar projects

 * https://github.com/dymatic/bpp/blob/master/bpp/sample.bpp
 * 

content of ```.phazes``` directory

 * .config
 * ```basename=<script>-<host>-<timestamp>```
 * basename.log saves command line arguments, working directory
 * basename.stdout (spli in phases with the sequence number?)
 * basename.err
 * ```basename-<seq>-<phase>.env``` for environment variables
 * do not allow phazes to run in home directory
 * be able to truncate logs to a certain size
 * --unlogged arguments to the preprocessor or specific phasein the script
 * --log-pipe='command' pipe log output throu a specified command before saving

## Examples
### loading data into the databse and creating a dump

```
phazes schema_init,generate,^load,create_dump dbgen.sh options
phazes --list [command [dates]]
--list-logs list runs info with log sizes
--continue [command [run timestamp or how many runs previoys]] continue from the phase previous execution stopped
--unlogged command
--clean-logs [hour|day|week|months|all]
--dry-run do not execute or log, only show what will happen
--verbose [commands,output,quite] can be specified for each phase also
--workdir [directory]
--phazesdir [directory]
--[no]check check the script for preprocessor correctness
--restore-env restore environment from saved variables
--prereq [phases] phases that must be executed before the specific phase
```