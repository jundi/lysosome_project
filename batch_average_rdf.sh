#!/bin/bash
set -e 

average() {
  system=$1
  residue=$2
  fep1=$3
  fep2=$4

  filelist=(\
    ${system}/analys/rdf_b50000/${residue}/50001-500000_rdf_leaflet_A.xvg \
    ${system}/analys/rdf_b50000/${residue}/50001-500000_rdf_leaflet_B.xvg \
    ${system}/free_energy${fep1}/analys/rdf_b10000/${residue}/1-100000_rdf_leaflet_A.xvg \
    ${system}/free_energy${fep1}/analys/rdf_b10000/${residue}/1-100000_rdf_leaflet_B.xvg \
    ${system}/free_energy${fep2}/analys/rdf_b10000/${residue}/1-100000_rdf_leaflet_A.xvg \
    ${system}/free_energy${fep2}/analys/rdf_b10000/${residue}/1-100000_rdf_leaflet_B.xvg \
    )
  #echo $filelist
  #echo ""
  filelist2=""
  for f in ${filelist[@]}; do
    echo "f = $f"
    echo ""
    f2="$(echo ${f} | cut -d . -f 1)_column1.xvg"
    echo "f2 =  $f2"
    echo ""
    echo "xvg_choose_column.py -c 1 -f ${f} -o _c"
    xvg_choose_column.py -c 1 -f ${f} -o ${f2}
    filelist2="${filelist2} ${f2}"
  done
  average-xvg.py ${filelist2} -o ${system}/analys/average_rdf_${residue}.xvg

}

#average "90POPC_10CHOL" "POPC" "" "2"
#average "60POPC_10CHOL_30CERA" "POPC" "3" "2"
#average "60POPC_10CHOL_30CERA" "CERA" "3" "2"
#average "60POPC_10CHOL_30DPPC" "POPC" "" "2"
#average "60POPC_10CHOL_30DPPC" "DPPC" "" "2"
#average "60POPC_10CHOL_30SM16" "POPC" "" "2"
#average "60POPC_10CHOL_30SM16" "SM16" "" "2"
average "60POPC_10CHOL_30LBPA22RR" "POPC" "3" "2"
average "60POPC_10CHOL_30LBPA22RR" "LBPA" "3" "2"

