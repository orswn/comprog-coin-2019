#!/bin/bash

# Requires gcc, GNU Coreutils, and "perf" from "linux-tools" package.
# Some distros may require root access for perf.
# Usage: 
# # ./scorer.sh <.c/.cpp file> <test case file> <output test file>

# Check if file exist
if [ ! -f $1 ]; then
    echo "File doesn't exist!";
    exit 1;
fi

# Assign the variables
FILE=$1;                            # "example.cpp"
DIR=$(dirname $FILE)                # Source Directory                
FILENAME=${FILE%.*};                # "example"
TYPE=${FILE#*.};                    # "cpp"
BASE=$(basename $FILENAME .$TYPE);  # "case5"

CASEFILE=$2                         # "case5.in"
CASE=$(basename $CASEFILE .in);     # "case5"

COMPARE=$3;                         # "case5.out"

SCRDIR="$DIR/$BASE-score"           # Directory for Scores
SCORING="$SCRDIR/$BASE-$CASE";      # "example-case5"

# perf stat with 10 runs and .log file to get
# the average statistics of a command
PERF="perf stat -r 10 --append -o $SCORING.log";

# Execution command with testcase input
EXEC="./$FILENAME < $CASEFILE";

# Remove files from previous run
rm -rf $FILENAME $SCORING{.log,.final,.out} >/dev/null 2>&1;

# Check file type for compiler type
if [ "$TYPE" = "c" ]; then
    CC="gcc";
elif [ "$TYPE" = "cpp" ]; then
    CC="g++";
else
    echo "File is not valid!";
    exit 1;
fi

# Compile command
COMPILE="$CC -O0 -std=c++11 -o $FILENAME $FILE >/dev/null 2>&1";

# Make a folder for scoring
mkdir $SCRDIR >/dev/null 2>&1;

# Test whether the the file can be compiled
# Failed to compile, exit
if ! eval "$COMPILE" >/dev/null; then 
    echo \
    "
    ### Failed to Compile ###
    File                    : $FILE
    Score                   : 0
    " | tee $SCORING.final; 
    exit 0;

# Compiled successfully
else
    # Execute with timeout of 5 minutes
    timeout 5m sh -c "$EXEC > $SCORING.out";
    
    # Exit if more than 5 minutes
    if [ $? -eq 124 ]; then
        echo \
    "
    ### Execution Timeout ###
    File                    : $FILE
    Case File               : $CASEFILE
    Score                   : 0
    " | tee $SCORING.final; 
        exit 0;
    fi
fi

# Check the output with test file
# If differ, exit
if ! diff -ZBq $SCORING.out $3 >/dev/null; then
    echo \
    "
    ### Wrong Output ###
    File                    : $FILE
    Case File               : $CASEFILE
    Output                  : $(cat $SCORING.out)
    Expected Output         : $(cat $COMPARE)
    Score                   : 0
    " | tee $SCORING.final;
    exit 0;

# Else, proceed scoring
else
    # Run Compile command and execute
    eval "$PERF $COMPILE";
    eval "$PERF sh -c '$EXEC >/dev/null'";

    # Get the time from the log file and binary size from "du" command
    COMPTIME=$(awk '/elapsed/{print $1 * 1000}' $SCORING.log | head -1);
    EXECTIME=$(awk '/elapsed/{print $1 * 1000}' $SCORING.log | tail -1);
    EXECSIZE=$(du -b $FILENAME | cut -f1)

	# Initial Score = 1000
	# Compilation Time Score = Compilation Time (ms) / 1
	# Execution Time Score = Execution Time (ms) / 10
	# Executable Size Score = Executable Size (bytes) / 1000
    SCORE=$( \
        echo "scale=2; 1000 - $COMPTIME - ($EXECTIME/10) - ($EXECSIZE/1000)" \
        | bc -l);

    # Output relevant information to stdout and .final file
    echo \
    "
    File                    : $FILE
    Case File               : $CASEFILE
    Compile Time (10 runs)  : $COMPTIME millisecond
    Execute Time (10 runs)  : $EXECTIME millisecond
    Executable Size         : $EXECSIZE Bytes
    Score                   : $SCORE
    " | tee $SCORING.final;
fi

exit 0;
