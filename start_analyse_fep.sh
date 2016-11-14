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

script=$(readlink -f ../scripts/batch-analyse.sh)
for s in ${systems[@]}; do
  echo $s

  for l in leaflet_A leaflet_B; do
    mkdir -p $s/free_energy/$l/analys
    cd $s/free_energy/$l/analys
    pwd
    $script -b 100000 bar dist_fep densmap_fep
    $script -b 10000 bar
    $script -b 100000 rdf -n ../../../index.ndx -s ../prod/lambda0/topol.tpr -f ../prod/lambda0/traj_comp.xtc
    $script -b 10000 rdf -n ../../../index.ndx -s ../prod/lambda0/topol.tpr -f ../prod/lambda0/traj_comp.xtc
    cd -
  done

done
