#!/bin/bash

for f in "$@"; do
  D=$(grep "D\[" $f  | awk '{print $5}')
  deltaD=$(grep "D\[" $f  | awk '{print $7}' | cut -d ')' -f 1 )
  echo "$D $deltaD"
done

