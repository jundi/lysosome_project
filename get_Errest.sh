#!/bin/bash
set -e

#----------------------------------
# Uncomment systems for calculation
#----------------------------------
systems=(
90POPC_10CHOL \
60POPC_10CHOL_30DPPC \
60POPC_10CHOL_30CERA \
60POPC_10CHOL_30SM16 \
60POPC_10CHOL_30LBPA22RR \
)

#---------------------------------------------------
# Set time (ps) to skip from beginning of trajectory
#---------------------------------------------------
declare -A begin
begin["90POPC_10CHOL"]=50000
begin["60POPC_10CHOL_30DPPC"]=50000
begin["60POPC_10CHOL_30CERA"]=50000
begin["60POPC_10CHOL_30SM16"]=50000
begin["60POPC_10CHOL_30LBPA22RR"]=50000



#-----------------------
# Simple errest function
#-----------------------
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
    local av=0
    local ee=0
  fi
  echo $av $ee
}

#------------------------------
# STE of data points (diff.xvg)
#------------------------------
ee_diffusion(){
  local data_file=$1
  if [[ -a $data_file ]]; then
    local line=$(gmx analyze -f $data_file 2>&1 | grep SS1)
    local av=$(echo $line | awk '{print $2}')
    local ee=$(echo $line | awk '{print $4}')
  else
    local av=0
    local ee=0
  fi
  echo $av $ee
}


#----------------------------
# Errest of gmx msd (msd.xvg)
#----------------------------
ee_msd(){
  local data_file=$1
  if [[ -a $data_file ]]; then
    local D=$(grep "D\[" $data_file | awk '{print $5}')
    local ee=$(grep "D\[" $data_file | awk '{print $7}' | cut -d ')' -f 1 )
  else
    local D=0
    local ee=0
  fi
  echo $D $ee
}


for s in ${systems[@]}; do

  # name of extra lipid
  lipid=$(echo $s | cut -d "0" -f 4 | head -c4)

  #------------------------------
  # Uncomment analysis to be done
  #------------------------------
  #contacts_POPC=( $(ee_analyze $s/analys/contacts/numcount_POPC.xvg 0 ${begin[$s]}) )
  #contacts_DPPC=( $(ee_analyze $s/analys/contacts/numcount_${lipid}.xvg 0 ${begin[$s]}) )
  #box=( $(ee_analyze $s/analys/box/box.xvg 0 ${begin[$s]}) )
  #sas_Membrane=( $(ee_analyze $s/analys/sas/Membrane-area.xvg 2 ${begin[$s]}) )
  #sas_POPC=( $(ee_analyze $s/analys/sas/POPC-area.xvg 2 ${begin[$s]}) )
  #sas_CHOL=( $(ee_analyze $s/analys/sas/CHOL-area.xvg 2 ${begin[$s]}) )
  #sas_DPPC=( $(ee_analyze $s/analys/sas/${lipid}-area.xvg 2 ${begin[$s]}) )
  #dist_POPCP=( $(ee_analyze $s/analys/dist/POPC_P/absz_average.xvg 0 ${begin[$s]}) )
  #dist_CHOLC3=( $(ee_analyze $s/analys/dist/CHOL_C3/absz_average.xvg 0 ${begin[$s]}) )
  #dist_CHOLC17=( $(ee_analyze $s/analys/dist/CHOL_C17/absz_average.xvg 0 ${begin[$s]}) )
  hbonds_POPC=( $(ee_analyze $s/analys/hbond/CHOL-POPC.xvg 0 ${begin[$s]}) )
  hbonds_DPPC=( $(ee_analyze $s/analys/hbond/CHOL-${lipid}.xvg 0 ${begin[$s]}) )

  #----------------------------------------------------
  # Uncomment leaflet to be used for diffusion analysis
  #----------------------------------------------------
  leaflet="" 		# both leaflets
  #leaflet="_leaflet_A"	# leaflet A
  #leaflet="_leaflet_B" # leaflet B

  #-----------------------------------------------------------
  # Uncomment the method for diffusion coefficient calculation
  #-----------------------------------------------------------
  #diff_POPC=( $(ee_diffusion $s/analys/msd/POPC/diff${leaflet}_b${begin[$s]}.xvg) )
  #diff_DPPC=( $(ee_diffusion $s/analys/msd/${lipid}/diff${leaflet}_b${begin[$s]}.xvg) )
  #diff_CHOL=( $(ee_diffusion $s/analys/msd/CHOL/diff${leaflet}_b${begin[$s]}.xvg) )
  #diff_POPC=( $(ee_msd $s/analys/msd/POPC/msd_atom${leaflet}_b${begin[$s]}.xvg) )
  #diff_POPC_P=( $(ee_msd $s/analys/msd/POPC_P/msd_atom${leaflet}_b${begin[$s]}.xvg) )
  #diff_DPPC=( $(ee_msd $s/analys/msd/${lipid}/msd_atom${leaflet}_b${begin[$s]}.xvg) )
  #diff_CHOL=( $(ee_msd $s/analys/msd/CHOL/msd_atom${leaflet}_b${begin[$s]}.xvg) )
  #diff_POPC=( $(ee_msd $s/analys/msd/POPC/msd_mol${leaflet}_b${begin[$s]}.xvg) )
  #diff_POPC_P=( $(ee_msd $s/analys/msd/POPC_P/msd_mol${leaflet}_b${begin[$s]}.xvg) )
  #diff_DPPC=( $(ee_msd $s/analys/msd/${lipid}/msd_mol${leaflet}_b${begin[$s]}.xvg) )
  #diff_CHOL=( $(ee_msd $s/analys/msd/CHOL/msd_mol${leaflet}_b${begin[$s]}.xvg) )
 

  # Print everything...
  echo "${contacts_POPC[0]} ${contacts_POPC[1]} ${contacts_DPPC[0]} ${contacts_DPPC[1]} ${box[0]} ${box[1]} ${sas_Membrane[0]} ${sas_Membrane[1]} ${sas_POPC[0]} ${sas_POPC[1]} ${sas_CHOL[0]} ${sas_CHOL[1]} ${sas_DPPC[0]} ${sas_DPPC[1]} ${dist_POPCP[0]} ${dist_POPCP[1]} ${dist_CHOLC3[0]} ${dist_CHOLC3[1]} ${dist_CHOLC17[0]} ${dist_CHOLC17[1]} ${diff_POPC[0]} ${diff_POPC[1]} ${diff_DPPC[0]} ${diff_DPPC[1]} ${diff_CHOL[0]} ${diff_CHOL[1]} ${diff_POPC_P[0]} ${diff_POPC_P[1]}${hbonds_POPC[0]} ${hbonds_POPC[1]} ${hbonds_DPPC[0]} ${hbonds_DPPC[1]}"

done
