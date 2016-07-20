#!/bin/bash
set -e

systems=(150POPC_20CHOL_30CERA \
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
60POPC_10CHOL_30CERA/free_energy_other_leaflet/ \
60POPC_10CHOL_30SM16/free_energy_other_leaflet/ \
)

for s in ${systems[@]}; do
  #barint=$(ls $s/analys/bar/barint_4001-*)
  barint=$(ls $s/analys/bar/barint_1-*)
  #echo $barint
  value=$(tail -n 1 $barint | awk '{print $2}')
  error=$(tail -n 1 $barint | awk '{print $3}')
  echo "$s $value $error"
done

