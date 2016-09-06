#!/bin/bash

rm diff.xvg
files=$(ls diff_* | sort -t _ -k2n)
for f in $files; do
  endfit=$(echo $f | cut -d _ -f2 | cut -d . -f1)
  line=$(gmx analyze -f $f 2>&1 | grep SS1)
  avg=$(echo $line | awk '{print $2}')
  std=$(echo $line | awk '{print $3}')
  ste=$(echo $line | awk '{print $4}')
  #echo "$endfit $avg $std $ste" >> diff.xvg
  echo "$endfit $avg $ste" >> diff.xvg
done

