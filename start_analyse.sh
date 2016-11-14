#!/bin/bash
set -e 

systems=( \
#90POPC_10CHOL \
#60POPC_10CHOL_30CERA \
#60POPC_10CHOL_30DPPC \
#60POPC_10CHOL_30SM16 \
#60POPC_10CHOL_30LBPA22RR \
60POPC_10CHOL_30LBPA16 \
#60POPC_10CHOL_30LBPA14 \
)

script=$(readlink -f ../scripts/batch-analyse.sh)
for s in ${systems[@]}; do
  echo $s

  cd $s/analys
  $script -f ../npt/traj_comp.xtc rdf contacts hbond
  cd -

done

systems=( \
#90POPC_10CHOL \
#60POPC_10CHOL_30CERA \
#60POPC_10CHOL_30DPPC \
#60POPC_10CHOL_30SM16 \
#60POPC_10CHOL_30LBPA22RR \
#60POPC_10CHOL_30LBPA16 \
60POPC_10CHOL_30LBPA14 \
)

script=$(readlink -f ../scripts/batch-analyse.sh)
for s in ${systems[@]}; do
  echo $s

  cd $s/analys
  $script -f ../npt/traj_comp.xtc rms sas density dist msd rdf contacts hbond
  cd -

done

