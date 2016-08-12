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
  if [[ -a $data_file ]]; then
    local data_index=$2
    local ee_index
    let ee_index=$data_index+1
    local ee_file="$(echo "$data_file" | cut -d . -f 1)_ee.xvg" 
    gmx analyze -f $data_file -ee $ee_file >/dev/null 2>&1 
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
  contacts_POPC=( $(ee_analyze $s/analys/contacts/numcount_POPC.xvg 0) )
  contacts_DPPC=( $(ee_analyze $s/analys/contacts/numcount_${lipid}.xvg 0) )


  echo "${contacts_POPC[0]} ${contacts_POPC[1]} ${contacts_DPPC[0]} ${contacts_DPPC[1]}"
done



