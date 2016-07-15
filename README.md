# phases
## Minimally Invasive bash Preprocessor

I have to maintain several shell scripts that perform long sequences of steps like loading data into a database or running a simulation model with pre- and post-processing of the data.  There are often failures and scripts has to be rerun starting at some point.  With this preprocessor one can define sections of the script that can be selected for execution using command line parameters.  

## Usage

Insert the directive ```#phase <name>``` into your script to split the script into sections.  Use ```test_script.sh``` as an example.  Give some meaningful name for each phase.  

Now you can select a phase or several from your script to be executed independently of others.  In the following example only the phase ```load``` will be executed:

```
phases load test_script.sh
```

To executed all other phases except for ```load``` use the option ```--skip```:

```
phases --skip load test_script.sh
```

For more help run ```phases``` without arguments.

### Phase List

Phase list contains the names of phases to be executed or skipped.  Multiple phases can be specified using comma:

```
phases load,final test_script.sh
```

To specify a range of phases use dash (```-```):

```
phases load-final test_script.sh
```

You can mix phases and ranges:

```
phases load,final-clean test_script.sh
```

To skip a phase use either ```--skip``` option or caret before the phase name in the list.  The following command will execute all phases except for ```load```:

```
phases ^load test_script.sh
```

### Implied ```init``` Phase

Any script starts with an implied phase ```init``` that starts at the first line of the script and ends before the first specified phase.  This phases is intended for various script initialization tasks like setting variables, defining functions, opening session, checks, etc.  This phases will be always executed unless skipped explicitly either with ```--skip``` option or with caret (```^```) in the phase list.

### Details

In skip mode negated phases are simply ignored.  The order of phases in the list does not matter and the sequence phases will always be preserved as in the original script.

## Other Useful Options

To make sure that all specified phases are properly understood run:

```
phases -l test_script.sh
```

Use ```--output``` option to save resulting script into a file instead of executing it.

# Limitations

1.  Inside your script do not use file paths relative to the script location
2.  The names of the phases should contain punctuation or special characters
