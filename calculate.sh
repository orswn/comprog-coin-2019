#!/bin/bash

# This script will find all c and cpp files in the directory
# and score them accordingly with scorer.sh script.
# This script may need root access for the scorer.sh script.
# usage:
# # ./calculate.sh

# Remove score from previous run
rm -f score >/dev/null 2>&1;

# For every cpp or c files
for i in $(find * -name '*.cpp' -or -name "*.c" | sort); do
    # Variables
    SCORESUM=0
    DIR=$(dirname $i)
    PROBLEM=$(basename $i .cpp | grep -o '[0-9]*');
    CASEDIR="Test-Cases/soal-$PROBLEM";

    # Test against 5 testcases
    for j in {1..5}; do
        ./scorer.sh $i $CASEDIR/case$j.in $CASEDIR/case$j.out;
    done

    # Sum all the scores from every testcase
    for k in $(find $DIR/*$PROBLEM-score -name '*.final' | sort); do
        SCORESUM=$(echo "$SCORESUM + $(awk '/Score/{print $NF}' $k)" | bc -l);
    done
	
	# Log the total scores to a file
    echo "Problem $PROBLEM  : $SCORESUM " >> $DIR/score;
done

# Output all the scores
for i in $(find . -name "score" | sort); do
    echo $i
    cat $i;
    echo "";
done | tee Final-Score.txt
