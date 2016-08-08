#!/bin/bash
set -e

systems=(
#180POPC_20CHOL \
#150POPC_20CHOL_30CERA \
#150POPC_20CHOL_30SM16 \
#150POPC_20CHOL_30LBPA22RR \
#150POPC_20CHOL_30LBPA22SS \
#20CHOL_180CERA \
#20CHOL_180SM16 \
90POPC_10CHOL/free_energy \
90POPC_10CHOL/free_energy2 \
60POPC_10CHOL_30DPPC/free_energy \
60POPC_10CHOL_30DPPC/free_energy2 \
60POPC_10CHOL_30CERA/free_energy \
60POPC_10CHOL_30CERA/free_energy2 \
60POPC_10CHOL_30SM16/free_energy \
60POPC_10CHOL_30SM16/free_energy2 \
60POPC_10CHOL_30LBPA22RR/free_energy \
60POPC_10CHOL_30LBPA22RR/free_energy2 \
60POPC_10CHOL_30LBPA22RR/free_energy3 \
#199POPC_1CHOL \
#169POPC_1CHOL_30CERA \
#169POPC_1CHOL_30SM16 \
#169POPC_1CHOL_30LBPA22RR \
#169POPC_1CHOL_30LBPA22SS \
#74POPC_10CHOL_16LBPA22RR \
#74POPC_10CHOL_16LBPA22SS \
)

for s in ${systems[@]}; do
  barint=$(find -wholename "*$s/analys/bar/barint_4001-*")
  #echo $barint
  if [[ -z $barint ]]; then
    value=0
    error=0
  else
    value=$(tail -n 1 $barint | awk '{print $2}')
    error=$(tail -n 1 $barint | awk '{print $3}')
  fi
  echo "$s $value $error"
done

