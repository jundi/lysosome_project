#!/bin/bash
set -e 

systems=( \
#150POPC_20CHOL_30CERA \
#150POPC_20CHOL_30LBPA22RR \
#150POPC_20CHOL_30LBPA22SS \
#150POPC_20CHOL_30SM16 \
#169POPC_1CHOL_30CERA \
#169POPC_1CHOL_30LBPA22RR \
#169POPC_1CHOL_30LBPA22SS \
#169POPC_1CHOL_30SM16 \
#180POPC_20CHOL \
#199POPC_1CHOL \
#20CHOL_180CERA \
#20CHOL_180SM16 \
#74POPC_10CHOL_16LBPA22RR \
#74POPC_10CHOL_16LBPA22SS \
60POPC_10CHOL_30CERA \
60POPC_10CHOL_30DPPC \
60POPC_10CHOL_30SM16 \
60POPC_10CHOL_30LBPA22RR \
90POPC_10CHOL \
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
