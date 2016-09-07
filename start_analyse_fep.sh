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
90POPC_10CHOL/free_energy/ \
90POPC_10CHOL/free_energy2/ \
60POPC_10CHOL_30CERA/free_energy3/ \
60POPC_10CHOL_30CERA/free_energy2/ \
60POPC_10CHOL_30DPPC/free_energy/ \
60POPC_10CHOL_30DPPC/free_energy2/ \
60POPC_10CHOL_30SM16/free_energy/ \
60POPC_10CHOL_30SM16/free_energy2/ \
60POPC_10CHOL_30LBPA22RR/free_energy3/ \
60POPC_10CHOL_30LBPA22RR/free_energy2/ \
)

script=$(readlink -f ../scripts/batch-analyse.sh)
for s in ${systems[@]}; do
  echo $s

  cd $s/analys
  $script -b 100000 rdf -n ../../index.ndx -s ../prod/lambda0/topol.tpr -f ../prod/lambda0/traj_comp.xtc
  cd -

done
