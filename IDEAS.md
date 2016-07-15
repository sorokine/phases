# Features
 * [ ] syntax checker
 * [ ] subphases can be implemented using multiple #
 * [x] be able to say 'run the rest' or 'skip the rest'
 * [x] to indicate a phase to skip use caret ```^```
 * [x] specify phase either by name or by sequence
 * [ ] conditional runs or skips of phases
 * [ ] either-or phases
 * [x] list phases in a script
 * [x] reporting of phase execution
 * [ ] facility for logging
     * log results of all commands from current run separately into .err and .out files
     * a log with all script runs with timer, working directory variable values
 * [ ] ability to restart from the point it failed on previous run
 * [ ] properly handle ^C and other signals
 * [ ] record the results of earlier runs (create .phases directory?)
 * [ ] check if variables set in the skipped phase are used in the later executed phases
 * [ ] what do I do with the shebang?
 * [ ] warning for comments with no space after #
 * [ ] git-aware (as an option)
 * [ ] non-bash interpreters (LaTeX, psql)
     * other comment character
     * library of supported interpreters
     * specific interpreter for each phase
          * can be specified through shebang option
 * [ ] optional end of phase in the script ```#^phase [name]```
 * [ ] verbosity and logging levels (can be set separately)
     * only errors
     * +phase names
     * +all stderr
     * +filtered stdout
     * +unfiltered stdout
 * [x] most options can be specified for either command line or in #phase
 * [ ] execution only specific lines (until/after/...)
 * [ ] printout what is being executed with optional confirmation
 * [ ] do not allow phases to be run in home directory
 * [ ] truncate logs to a certain size

# Ideas for Command-line Options
 * [ ] --unlogged arguments to the preprocessor or specific phase in the script
 * [ ] --log-pipe='command' pipe log output through a specified command before saving
 * [ ] --list-logs list runs information with log sizes
 * [ ] --continue [command [run timestamp or how many run previously]] continue from the phase previous execution stopped
 * [ ] --unlogged command
 * [ ] --clean-logs [hour|day|week|months|all]
 * [ ] --dry-run do not execute or log, only show what will happen
 * [ ] --verbose [commands,output,quite] can be specified for each phase also
 * [ ] --workdir [directory]
 * [ ] --phasesdir [directory]
 * [ ] --[no]check check the script for preprocessor correctness
 * [ ] --restore-env restore environment from saved variables
 * [ ] --prereq [phases] phases that must be executed before the specific phase

# Motivation

 * if implemented with standard bash facilities the original script becomes too long and it is hard to grasp what it does
 * the goal of phases is somewhat similar to Makefile, maven or ant but  targets are hard to define if they cannot be presented as files

# Similar projects

 * https://github.com/dymatic/bpp/blob/master/bpp/sample.bpp but it is doing something completely different

# Content of the ```.phases``` directory

 * .config
 * ```basename=<script>-<host>-<timestamp>```
 * basename.log saves command line arguments, working directory
 * basename.stdout (split in phases with the sequence number?)
 * basename.err
 * ```basename-<seq>-<phase>.env``` for environment variables

## Examples
### loading data into the database and creating a dump

```
  phases schema_init,generate,^load,create_dump dbgen.sh options
  phases --list [command [dates]]
```
