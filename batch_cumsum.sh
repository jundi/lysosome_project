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
#90POPC_10CHOL/free_energy/analys/bar_b100000/1-100000 \
#90POPC_10CHOL/free_energy2/analys/bar_b100000/1-100000 \
#60POPC_10CHOL_30CERA/free_energy/analys/bar_b100000/1-100000 \
#60POPC_10CHOL_30CERA/free_energy2/analys/bar_b100000/1-100000 \
#60POPC_10CHOL_30CERA/free_energy3/analys/bar_b100000/1-100000 \
#60POPC_10CHOL_30DPPC/free_energy/analys/bar_b100000/1-100000 \
#60POPC_10CHOL_30DPPC/free_energy2/analys/bar_b100000/1-100000 \
#60POPC_10CHOL_30SM16/free_energy/analys/bar_b100000/1-100000 \
#60POPC_10CHOL_30SM16/free_energy2/analys/bar_b100000/1-100000 \
60POPC_10CHOL_30LBPA22RR/free_energy/analys/bar_b100000/1-100000 \
#60POPC_10CHOL_30LBPA22RR/free_energy2/analys/bar_b100000/1-100000 \
#60POPC_10CHOL_30LBPA22RR/free_energy3/analys/bar_b100000/1-100000 \
)

for s in ${systems[@]}; do
  echo $s

  cd $s
  #xvg_cumsum.py -f bar.xvg -o bar_cumsum.xvg 
  xvg_cumsum.py -f bar.xvg -o bar_cumsum_SSE.xvg -c 1 -e 2
  cd -

done
