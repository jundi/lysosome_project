#!/bin/bash
set -e

systems=(
90POPC_10CHOL \
60POPC_10CHOL_30DPPC \
60POPC_10CHOL_30CERA \
60POPC_10CHOL_30SM16 \
60POPC_10CHOL_30LBPA22RR \
)

declare -A begin
begin["90POPC_10CHOL"]=30000
begin["60POPC_10CHOL_30DPPC"]=30000
begin["60POPC_10CHOL_30CERA"]=30000
begin["60POPC_10CHOL_30SM16"]=30000
begin["60POPC_10CHOL_30LBPA22RR"]=30000

ee_analyze(){
  local data_file=$1
  local data_index=$2
  local begin=$3
  if [[ -a $data_file ]]; then
    local ee_index
    let ee_index=$data_index+1
    local ee_file="$(echo "$data_file" | cut -d . -f 1)_ee.xvg" 
    gmx analyze -f $data_file -b $begin -ee $ee_file >/dev/null 2>&1
    local av=$(grep "s${data_index} legend \"av" $ee_file | cut -d '"' -f 2 | awk '{print $2}')
    local ee=$(grep "s${ee_index} legend \"ee" $ee_file | cut -d '"' -f 2 | awk '{print $2}')
  else
    av=0
    ee=0
  fi
    echo $av $ee
}


for s in ${systems[@]}; do

  lipid=$(echo $s | cut -d "0" -f 4 | head -c4)
  contacts_POPC=( $(ee_analyze $s/analys/contacts/numcount_POPC.xvg 0 ${begin[$s]}) )
  contacts_DPPC=( $(ee_analyze $s/analys/contacts/numcount_${lipid}.xvg 0 ${begin[$s]}) )
  box=( $(ee_analyze $s/analys/box/box.xvg 0 ${begin[$s]}) )
  sas_Membrane=( $(ee_analyze $s/analys/sas/Membrane-area.xvg 2 ${begin[$s]}) )
  sas_POPC=( $(ee_analyze $s/analys/sas/POPC-area.xvg 2 ${begin[$s]}) )
  sas_CHOL=( $(ee_analyze $s/analys/sas/CHOL-area.xvg 2 ${begin[$s]}) )
  sas_DPPC=( $(ee_analyze $s/analys/sas/${lipid}-area.xvg 2 ${begin[$s]}) )
  dist_POPCP=( $(ee_analyze $s/analys/dist/POPC_P/absz_average.xvg 0 ${begin[$s]}) )
  dist_CHOLC3=( $(ee_analyze $s/analys/dist/CHOL_C3/absz_average.xvg 0 ${begin[$s]}) )
  dist_CHOLC17=( $(ee_analyze $s/analys/dist/CHOL_C17/absz_average.xvg 0 ${begin[$s]}) )
 

  echo "${contacts_POPC[0]} ${contacts_POPC[1]} ${contacts_DPPC[0]} ${contacts_DPPC[1]} ${box[0]} ${box[1]} ${sas_Membrane[0]} ${sas_Membrane[1]} ${sas_POPC[0]} ${sas_POPC[1]} ${sas_CHOL[0]} ${sas_CHOL[1]} ${sas_DPPC[0]} ${sas_DPPC[1]} ${dist_POPCP[0]} ${dist_POPCP[1]} ${dist_CHOLC3[0]} ${dist_CHOLC3[1]} ${dist_CHOLC17[0]} ${dist_CHOLC17[1]} "
done



