#!/bin/sh

# Requires gcc and "perf-stat" from "linux-tools" package
# Usage: 
# $ sudo ./calculate.sh <.c/.cpp file>

# Check if file exist
if [ ! -f $1 ]; then
    echo "File doesn't exist!"
    exit 1
fi

# Split the file name
FILE=$1             # "example.cpp"
BASE=${FILE%.*}     # "example"
TYPE=${FILE#*.}     # ".cpp"

# perf stat with 100 runs and .log file to get
# the average statistics of a command
PERF="perf stat -r 100 --append -o $BASE.log "

# Remove files from previous run
rm $BASE $BASE.final $BASE.log >/dev/null 2>&1

# Check file type for compilation command
if [ "$TYPE" = "c" ]; then
    COMPILE="gcc -O0 -Wall -std=c11 -o $BASE $FILE"
elif [ "$TYPE" = "cpp" ]; then
    COMPILE="g++ -O0 -Wall -std=c++11 -o $BASE $FILE"
else
    echo "File is not valid!"
    exit 1
fi

# Run Compile command and execute
$PERF $COMPILE
$PERF ./$BASE

# Get time from the log file and binary size from "du" command
COMPTIME=$(awk '/elapsed/{print $1}' $BASE.log | head -1)
EXECTIME=$(awk '/elapsed/{print $1}' $BASE.log | tail -1)
EXECSIZE=$(du -b $BASE | cut -f1)

# Output relevant information to stdout and .final file
echo "
File                    : $FILE
Compile Time (100 runs) : $COMPTIME millisecond
Execute Time (100 runs) : $EXECTIME millisecond
Executable Size         : $EXECSIZE Bytes
" | tee $BASE.final
