#!/bin/bash
set -e 

systems=( \
150POPC_20CHOL_30CERA \
150POPC_20CHOL_30LBPA22RR \
150POPC_20CHOL_30LBPA22SS \
150POPC_20CHOL_30SM16 \
169POPC_1CHOL_30CERA \
169POPC_1CHOL_30LBPA22RR \
169POPC_1CHOL_30LBPA22SS \
169POPC_1CHOL_30SM16 \
180POPC_20CHOL \
199POPC_1CHOL \
20CHOL_180CERA \
20CHOL_180SM16 \
60POPC_10CHOL_30CERA \
60POPC_10CHOL_30DPPC \
60POPC_10CHOL_30SM16 \
74POPC_10CHOL_16LBPA22RR \
74POPC_10CHOL_16LBPA22SS \
90POPC_10CHOL \
)

script=$(readlink -f ../scripts/batch-analyse.sh)
for s in ${systems[@]}; do
  echo $s

  cd $s/analys/contacts/
  for f in *xvg; do
    xvg_runningmean.py -f $f -n 10
    xvg_runningmean.py -f $f -n 20
    xvg_runningmean.py -f $f -n 50
    xvg_runningmean.py -f $f -n 100
    xvg_runningmean.py -f $f -n 200
  done
  cd -

done
