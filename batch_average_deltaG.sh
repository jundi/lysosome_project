#!/bin/bash
set -e 

temp=310
nbmin=6
nbmax=10
prec=4

systems=(
#90POPC_10CHOL \
60POPC_10CHOL_30DPPC \
60POPC_10CHOL_30CERA \
60POPC_10CHOL_30SM16 \
60POPC_10CHOL_30LBPA22RR \
)

for s in ${systems[@]}; do
  avgdir="$s/free_energy/average"
  mkdir -p  $avgdir/leaflet_A
  mkdir -p  $avgdir/leaflet_B
  mkdir -p  $avgdir/both_leaflets

  # cut and paste original dhdl-files
  dhdl_files=""
  for lambda in {0..15}; do

    for leaflet in A B; do
      echo "$s/free_energy/leaflet_${leaflet}/prod/lambda${lambda}/dhdl.xvg"
      xvg_cut.py -f $s/free_energy/leaflet_${leaflet}/prod/lambda${lambda}/dhdl.xvg -o $avgdir/leaflet_${leaflet}/dhdl_$lambda.xvg -b 0 -e 100000
    done

    xvg_cat.py -f $avgdir/leaflet_A/dhdl_$lambda.xvg $avgdir/leaflet_B/dhdl_$lambda.xvg -o $avgdir/both_leaflets/dhdl_$lambda.xvg
    dhdl_files="$dhdl_files $avgdir/both_leaflets/dhdl_$lambda.xvg"

  done
  echo $dhdl_files

  # GMX BAR
  gmx bar -f $dhdl_files -o $avgdir/bar.xvg -oi $avgdir/barint.xvg -oh $avgdir/histogram.xvg -nbmin $nbmin -nbmax $nbmax -prec $prec -temp $temp

done
