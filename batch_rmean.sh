#!/bin/bash
set -e 

systems=( \
#60POPC_10CHOL_30CERA \
#60POPC_10CHOL_30DPPC \
60POPC_10CHOL_30LBPA14 \
60POPC_10CHOL_30LBPA16 \
#60POPC_10CHOL_30LBPA22RR \
#60POPC_10CHOL_30SM16 \
#90POPC_10CHOL \
)


for s in ${systems[@]}; do
  echo $s
  cd $s

  # contacts
  for f in $(find -wholename "*contacts/numcount_r???_????.xvg"); do
    xvg_blockmean.py -f $f -n 100
  done
  for f in $(find -wholename "*contacts/numcount_r???_Water.xvg"); do
    xvg_blockmean.py -f $f -n 100
  done

  # sasa
  for f in $(find -wholename "*sas/*-area.xvg"); do
    xvg_blockmean.py -f $f -n 20
    xvg_blockmean.py -f $f -n 50
  done

  # box
  for f in $(find -wholename "*box/box.xvg"); do
    xvg_blockmean.py -f $f -n 500
  done

  # dist
  for f in $(find -wholename "*dist/*/absz_average.xvg"); do
    xvg_blockmean.py -f $f -n 20
  done
  for f in $(find -wholename "*dist/*/z.xvg"); do
    xvg_blockmean.py -f $f -n 20
  done

  # hbonds
  for f in $(find -wholename "*hbond/CHOL-????.xvg"); do
    xvg_blockmean.py -f $f -n 100
  done


  cd -
done
