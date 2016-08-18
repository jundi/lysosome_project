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
#199POPC_1CHOL \
#169POPC_1CHOL_30CERA \
#169POPC_1CHOL_30SM16 \
#169POPC_1CHOL_30LBPA22RR \
#169POPC_1CHOL_30LBPA22SS \
#74POPC_10CHOL_16LBPA22RR \
#74POPC_10CHOL_16LBPA22SS \
#90POPC_10CHOL/free_energy \
#90POPC_10CHOL/free_energy2 \
#60POPC_10CHOL_30DPPC/free_energy \
#60POPC_10CHOL_30DPPC/free_energy2 \
#60POPC_10CHOL_30CERA/free_energy \
#60POPC_10CHOL_30CERA/free_energy2 \
60POPC_10CHOL_30CERA/free_energy3 \
#60POPC_10CHOL_30SM16/free_energy \
#60POPC_10CHOL_30SM16/free_energy2 \
#60POPC_10CHOL_30LBPA22RR/free_energy \
#60POPC_10CHOL_30LBPA22RR/free_energy2 \
#60POPC_10CHOL_30LBPA22RR/free_energy3 \
)

declare -A sim_length
sim_length["90POPC_10CHOL/free_energy"]=100000
sim_length["90POPC_10CHOL/free_energy2"]=40000
sim_length["60POPC_10CHOL_30DPPC/free_energy"]=100000
sim_length["60POPC_10CHOL_30DPPC/free_energy2"]=40000
sim_length["60POPC_10CHOL_30CERA/free_energy"]=100000
sim_length["60POPC_10CHOL_30CERA/free_energy2"]=50000
sim_length["60POPC_10CHOL_30CERA/free_energy3"]=100000
sim_length["60POPC_10CHOL_30SM16/free_energy"]=100000
sim_length["60POPC_10CHOL_30SM16/free_energy2"]=40000
sim_length["60POPC_10CHOL_30LBPA22RR/free_energy"]=40000
sim_length["60POPC_10CHOL_30LBPA22RR/free_energy2"]=40000
sim_length["60POPC_10CHOL_30LBPA22RR/free_energy3"]=100000


for s in ${systems[@]}; do

  # Block average
  #echo "*$s/analys/bar_b10000/barint_1-${sim_length[$s]}.xvg"
  blockavg=$(find -wholename "*$s/analys/bar_b10000/barint_1-${sim_length[$s]}.xvg")
  #echo $blockavg
  if [[ -z $blockavg ]]; then
    blockavg_val=0
    blockavg_err=0
  else
    blockavg_val=$(tail -n 1 $blockavg | awk '{print $2}')
    blockavg_err=$(tail -n 1 $blockavg | awk '{print $3}')
  fi

  # Cumulative sum
  #echo "*$s/analys/bar_b${sim_length[$s]}/1-${sim_length[$s]}/bar_cumsum.xvg"
  cumsum=$(find -wholename "*$s/analys/bar_b${sim_length[$s]}/1-${sim_length[$s]}/bar_cumsum.xvg")
  #echo $cumsum
  if [[ -z $cumsum ]]; then
    cumsum_val=0
    cumsum_err=0
  else
    cumsum_val=$(tail -n 1 $cumsum | awk '{print $2}')
    cumsum_err=$(tail -n 1 $cumsum | awk '{print $3}')
  fi

  echo "$s $blockavg_val $blockavg_err $cumsum_val $cumsum_err"
done

