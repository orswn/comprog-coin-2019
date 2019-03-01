#!/bin/sh

if [ ! -f $1 ]; then
    echo "File doesn't exist!"
    exit 1
fi

FILE=$1
BASE=${FILE%.*}
TYPE=${FILE#*.}
PERF="perf stat -r 100 --append -o $BASE.log "

rm $BASE $BASE.final $BASE.log >/dev/null 2>&1

if [ "$TYPE" = "c" ]; then
    COMPILE="gcc -O0 -Wall -std=c11 -o $BASE $FILE"
elif [ "$TYPE" = "cpp" ]; then
    COMPILE="g++ -O0 -Wall -std=c++11 -o $BASE $FILE"
else
    echo "File is not valid!"
    exit 1
fi

$PERF $COMPILE
$PERF ./$BASE >/dev/null

COMPTIME=$(awk '/elapsed/{print $1 * 1000}' $BASE.log | head -1)
EXECTIME=$(awk '/elapsed/{print $1 * 1000}' $BASE.log | tail -1)
EXECSIZE=$(echo "scale=2; $(du -b $BASE | cut -f1)/1000" | bc -l)

echo "
File                    : $FILE
Compile Time (100 runs) : $COMPTIME millisecond
Execute Time (100 runs) : $EXECTIME millisecond
Executable Size         : $EXECSIZE Bytes
"
