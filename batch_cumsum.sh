#!/bin/bash
set -e 

systems=( \
60POPC_10CHOL_30CERA \
60POPC_10CHOL_30DPPC \
60POPC_10CHOL_30LBPA14 \
60POPC_10CHOL_30LBPA16 \
60POPC_10CHOL_30LBPA22RR \
60POPC_10CHOL_30SM16 \
90POPC_10CHOL \
)

fepdirs=( \
"free_energy/leaflet_A/analys/bar_b100000/1-100000" \
"free_energy/leaflet_B/analys/bar_b100000/1-100000" \
"free_energy/average" \
)

for s in ${systems[@]}; do
  echo $s

  for d in ${fepdirs[@]}; do
    cd $s/$d
    pwd
    xvg_cumsum.py -f bar.xvg -o bar_cumsum.xvg 
    xvg_cumsum.py -f bar.xvg -o bar_cumsum_SSE.xvg -c 1 -e 2
    cd -
  done

done

