#!/bin/bash
set -e

##########################
# list of possible tasks #
##########################
task_options=(order rms sas box density bar dist dist_fep msd densmap densmap_fep rdf contacts hbond hbond_group)


##########
# manual #
##########
task_string=""
for t in ${task_options[@]}; do
  task_string="$task_string\t$t\n"
done
usage="\n
Usage: \n
\t$(basename $0) [OPTION...] [TASK1,TASK2,...] \n
\n
Example: \n
\t$ bash $(basename $0) -n index.ndx -s topol.tpr -f traj.xtc -b 100000 -j 4 order rms density \n
\n
Options: \n
\t-n \t index.ndx \n
\t-s \t topol.tpr \n
\t-f \t traj.xtc \n
\t-e \t ener.edr\n
\t-b \t block size for block average (ps) \n
\t-dt \t skip frames \n
\t-j \t max parallel jobs \n
\t-fep \t FEP calculation directory\n
\n
Tasks: \n
$task_string
\n
"


############
# defaults #
############
# input files
traj=$(readlink -m ../npt/traj_comp.xtc)
structure=$(readlink -m ../npt/topol.tpr)
edr=$(readlink -m ../npt/ener.edr)
if [[ -e ../index.ndx ]]; then
  index=$(readlink -m ../index.ndx)
else
  index=$(readlink -m ../../../index.ndx)
fi
fepdir=$(readlink -m ../prod)
# other parameters
block=10000	# block size for block average
dt=-1		# skip frames
maxjobs=4	# max parallel jobs


####################
# global variables #
####################
tasks=()       # array to store tasks


####################
# input parameters #
####################
if [[ $# -lt 1 ]]; then
  echo "Not enough input parameteres."
  exit 1
fi
while [[ $# -gt 0 ]]; do    
  case "$1" in
    -h)
      echo -e $usage
      exit 0
      ;;
    -s)
      structure=$(readlink -f $2)
      shift
      ;;
    -f)
      traj=$(readlink -f $2)
      shift
      ;;
    -n)
      index=$(readlink -f $2)
      shift
      ;;
    -e)
      edr=$(readlink -f $2)
      shift
      ;;
    -b)
      block="$2"
      shift
      ;;
    -dt)
      dt="$2"
      shift
      ;;
    -j)
      maxjobs="$2"
      shift
      ;;
    -fep)
      fepdir=$(readlink -f $2)
      shift
      ;;
    *)
      if [[ ${task_options[*]} =~ $1 ]]; then
	tasks+=("$1")
      else
	echo -e $usage
	exit 2
      fi
      ;;
  esac
  shift       
done



####################
# Helper functions #
####################
#------
# Main
main() {

  for task in ${tasks[@]} ;do
    mkdir -p logs
    echo -e "Calculating $task..."
    $task  >"logs/${task}.log" 2> "logs/${task}2.log"
  done

  sem --wait
  echo -e "All tasks completed."

}



#-----------------------
# timestamp of cpt file
timestamp() {
  local cptfile=$1
  local tmax_decimal=$(gmx check -f $cptfile 2>&1 | grep "Last frame" | awk '{print $NF}')
  if [[ -z  $tmax_decimal ]]; then
    tmax_decimal=$(gmx check -f $cptfile 2>&1 | grep "Reading frame" | tail -n1 | awk '{print $NF}')
  fi
  local tmax=$(echo $tmax_decimal/1 | bc) # decimal to integer
  echo $tmax
}



#--------------------------
# create working directory
mkwrkdir() {
  local wrkdir=$1
  if [[ -e $wrkdir ]]; then
    mv $wrkdir ${wrkdir}_backup_$(date +"%Y%m%d_%H%M%S")
  fi
  mkdir -p $wrkdir
}


#------------------------
# block average function 
block_average() {
  local cmd="$1"
  local lastframe="$2"

  local blocklist=""
  local b=1
  local e
  let e=$b+$block-1

  while [[ $e -le $lastframe ]]; do 
    blocklist=(${b}-${e} ${blocklist[*]})
    mkdir -p $b-$e
    cd $b-$e

    sem -j $maxjobs "$cmd -b $b -e $e"

    cd ..
    let b=$b+$block
    let e=$e+$block
  done

  sem --wait
  local xvgfiles=$(find ${blocklist[0]} -name "*.xvg")
  for x in $xvgfiles; do
    local xname=$(basename $x)
    local filelist=""
    local avg_lastframe=$(echo ${blocklist[0]} | cut -d '-' -f 2)
    for b in ${blocklist[@]}; do
      filelist="$b/${xname} $filelist"
      local avg_firstframe=$(echo ${b} | cut -d '-' -f 1)
      if [[ $(echo $filelist | wc -w) -gt 1 ]]; then
	average-xvg.py -o ${avg_firstframe}-${avg_lastframe}_${xname} $filelist
      fi
    done
  done

  join-xvg.py -l -o blocks_${xname} $filelist

}

#---------------------------
# Get the center of the box 
boxcenter() {
  local boxfile=$1
  local boxz=$(grep "s4 legend" $boxfile | awk '{print $5}' | cut -d \" -f 1)
  local boxzcenter=$(echo "scale=5; $boxz / 2" | bc -l)
  echo $boxzcenter
}


##################
# Task functions #
##################

#------
# rmsd
rms() {

  # settings
  ref_group="Membrane"
  group_list=("CHOL" "POPC" "LBPA" "CERA" "SM16")
  workdir=rms

  mkwrkdir $workdir
  cd $workdir

  # build target group string
  groups=""
  for g in ${group_list[@]}; do
    if [[ $(grep " $g " $index) ]]; then
      groups="${groups} ${g}"
    fi
  done
  echo "GROUPS: $groups"
  ng=$(echo $groups | wc -w)

  # g_rms
  echo "$ref_group $groups" | sem -j $maxjobs "gmx rms -f $traj -n $index -s $structure -ng $ng -what rmsd -dt $dt; xvg_runningmean.py -f rmsd.xvg -n 10"

  cd ..
}



#-----------------
# Order parameter
order() {

  # settings
  tailnames=("POPC_SN1" "POPC_SN2" "DPPC_SN1" "DPPC_SN2" "SM16_1" "SM16_2" "CERA_1" "CERA_2" "LBPA_1" "LBPA_2" "LBPA14_1" "LBPA14_2" "LBPA16_1" "LBPA16_2")
  workdir=order_b$block
  lastframe=$(timestamp $traj)

  mkwrkdir $workdir
  cd $workdir

  # Tail atoms
  for tn in ${tailnames[@]}; do

    case $tn in
      "POPC_SN1")
	atoms=(C31 C32 C33 C34 C35 C36 C37 C38 C39 C310 C311 C312 C313 C314 C315 C316)
	unsat=""
	;;
      "POPC_SN2")
	atoms=(C21 C22 C23 C24 C25 C26 C27 C28 C29 C210 C211 C212 C213 C214 C215 C216 C217 C218)
	unsat="9 10"
	;;
      "SM16_1")
	atoms=(C1 C2 C21 C22 C23 C24 C25 C26 C27 C28 C29 C210 C211 C212 C213 C214 C215 C216)
	unsat="4 5"
	;;
      "SM16_2")
	atoms=(C31 C32 C33 C34 C35 C36 C37 C38 C39 C310 C311 C312 C313 C314 C315 C316)
	unsat=""
	;;
      "CERA_1")
	atoms=(C1 C2 C21 C22 C23 C24 C25 C26 C27 C28 C29 C210 C211 C212 C213 C214 C215 C216)
	unsat="4 5"
	;;
      "CERA_2")
	atoms=(C31 C32 C33 C34 C35 C36 C37 C38 C39 C310 C311 C312 C313 C314 C315 C316)
	unsat=""
	;;
      "DPPC_SN1")
	atoms=(C31 C32 C33 C34 C35 C36 C37 C38 C39 C310 C311 C312 C313 C314 C315 C316)
	unsat=""
	;;
      "DPPC_SN2")
	atoms=(C21 C22 C23 C24 C25 C26 C27 C28 C29 C210 C211 C212 C213 C214 C215 C216)
	unsat=""
	;;
      "LBPA_1")
	atoms=(C21 C22 C23 C24 C25 C26 C27 C28 C29 C210 C211 C212 C213 C214 C215 C216 C217 C218)
	unsat="9 10"
	;;
      "LBPA_2")
	atoms=(C21\' C22\' C33 C34 C35 C36 C37 C38 C39 C310 C311 C312 C313 C314 C315 C316 C317 C318)
	unsat="9 10"
	;;
      "LBPA14_1")
	atoms=(C21 C22 C23 C24 C25 C26 C27 C28 C29 C210 C211 C212 C213 C214)
	unsat=""
	;;
      "LBPA14_2")
	atoms=(C21\' C22\' C33 C34 C35 C36 C37 C38 C39 C310 C311 C312 C313 C314)
	unsat=""
	;;
      "LBPA16_1")
	atoms=(C21 C22 C23 C24 C25 C26 C27 C28 C29 C210 C211 C212 C213 C214 C215 C216)
	unsat=""
	;;
      "LBPA16_2")
	atoms=(C21\' C22\' C33 C34 C35 C36 C37 C38 C39 C310 C311 C312 C313 C314 C315 C316)
	unsat=""
	;;
      *)
	echo "ERROR: Unknown tail"
	continue
	;;
    esac


    # Does residue exist?
    resname=$(echo $tn | cut -d "_" -f 1)
    if [[ ! $(grep " $resname " $index) ]]; then
      continue
    fi

    # create dir for this tail
    mkdir -p $tn
    cd $tn

    # Create index file for tail
    select=""
    for atom in ${atoms[@]}; do
      select="$select name \"$atom\" and resname $resname;"
    done
    gmx select -s $structure -select "$select" -on tailatoms.ndx


    # loop blocks
    b=1
    while [[ $b -lt $lastframe ]]; do

      let e=$b+${block}-1
      mkdir $b-$e

      gmx order -f $traj -nr $index -s $structure  -b $b -e $e -n tailatoms.ndx -o $b-$e/order.xvg -od $b-$e/deuter.xvg -dt $dt
      gmx order -f $traj -nr $index -s $structure  -b $b -e $e -n tailatoms.ndx -os $b-$e/sliced.xvg -dt $dt -sl 100 -szonly
      rm order.xvg

      if [[ -z $unsat ]]; then
	# just fix atom numbering
	xvg_fixdeuter.py -f $b-$e/deuter.xvg -o $b-$e/deuter_fixed.xvg
      else
	gmx order -f $traj -nr $index -s $structure  -b $b -e $e -n tailatoms.ndx -o $b-$e/order_unsat.xvg -od $b-$e/deuter_unsat.xvg -dt $dt -unsat
	gmx order -f $traj -nr $index -s $structure  -b $b -e $e -n tailatoms.ndx -os $b-$e/sliced_unsat.xvg -dt $dt -sl 100 -szonly -unsat
	rm order.xvg
	# merge saturated and unstaturated, and fix atom numbering
	xvg_fixdeuter.py -f $b-$e/deuter.xvg -u $b-$e/deuter_unsat.xvg -a $unsat -o $b-$e/deuter_fixed.xvg 
      fi

      let b=$b+$block

    done

    # compute averages
    allfiles=$(find -name deuter_fixed.xvg | sort -t / -k2nr)
    filelist=""
    for f in $allfiles; do
      filelist="$filelist $f"
      time1=$(echo $f | cut -d "/" -f2 | cut -d "-" -f1)
      time2=$(echo $filelist | cut -d "/" -f2 | cut -d "-" -f2)
      average-xvg.py -o ${time1}-${time2}_deuter_fixed.xvg $filelist
    done

    # join blocks to one file
    allfiles=$(find -name deuter_fixed.xvg | sort -t / -k2n)
    join-xvg.py -l -o deuter_fixed_blocks.xvg $allfiles


    cd .. # from tn
    
  done 

  cd .. # from workdir
}






#------------------------------
# SASA (Solvent accessble area
sas() {

  # settings
  groups=(POPC DPPC CERA LBPA SM16 CHOL Membrane)
  ref_group="Membrane"
  workdir=sas

  mkwrkdir $workdir
  cd $workdir

  for group in ${groups[@]}; do
    if [[ $(grep " $group " $index) ]]; then
      # gmx sasa
      sem -j $maxjobs gmx sasa -f $traj -n $index -s $structure -o $group-area.xvg -or $group-resarea.xvg -oa $group-atomarea.xvg -tv $group-volume.xvg -q $group-connelly.pdb -surface $ref_group -output $group  -dt $dt
    fi
  done

  cd ..
}





#----------
# Box size
box() {

  workdir=box

  mkwrkdir $workdir
  cd $workdir

  echo -e "Box-X\n Box-Y\n Box-Z" | gmx energy -f $edr -o box.xvg 

  cd ..
}





#---------
# Density
density() {

  # settings
  ref_group="Membrane"
  groups=("POPC" "CHOL" "CHOL_C3" "CHOL_C17" "LBPA" "CERA" "SM16" "DPPC")
  workdir=density_b$block
  sl=250 #slices
  dens="number"

  mkwrkdir $workdir
  cd $workdir


  lastframe=$(timestamp $traj)
  for group in ${groups[@]}; do

    if ! [[ $(grep "\[ $group \]" $index) ]]; then
      continue
    fi

    mkdir -p $group
    cd $group 

    cmd="echo \"$ref_group $group\" | gmx density -f $traj -s $structure -center -n $index -symm -sl $sl -dens $dens -o density_sl${sl}_${dens}.xvg -dt $dt"
    block_average "$cmd" $lastframe
    cd ..


  done

  cd ..

}



#--------------------------------
# BAR (Bennett Acceptance Ratio)
bar() {

  # settings
  workdir=bar_b$block
  temp=310
  nbmin=6
  nbmax=10
  prec=4

  mkwrkdir $workdir
  cd $workdir

  # last frame
  tmax=$(timestamp ${fepdir}/lambda0/state.cpt)
  echo "Last frame = $tmax"

  # create list of dhdl files
  dhdl=""
  for i in {0..15}; do
    dhdl="${dhdl} ${fepdir}/lambda${i}/dhdl.xvg"
  done

  cmd="gmx bar -f $dhdl -o bar.xvg -oi barint.xvg -oh histogram.xvg -nbmin $nbmin -nbmax $nbmax -prec $prec -temp $temp"
  block_average "$cmd" $tmax

  cd ..
}


#------------------------------
# Distance (normal simulation)
dist() {

  # settings
  workdir=dist
  ref="com of group Membrane"

  mkwrkdir $workdir
  cd $workdir

  for group in CHOL FepCHOL CHOL_C3 CHOL_C17 FepCHOL_C3 FepCHOL_C17 POPC_P; do
    if [[ $(grep "\[ $group \]" $index) ]]; then
      mkdir -p $group
      select="group $group"

	distance -s $structure -f $traj -n $index -oxyz $group/xyz.xvg -oz $group/z.xvg -oabsz $group/absz.xvg -ref "$ref" -select "$select"  -seltype "res_com" -dt $dt

	average-xvg.py $group/absz.xvg -o $group/absz_average.xvg
      fi
    done
    cd ..
}


#----------------------------
# Distance (FEP simulations)
dist_fep() {

  # settings
  workdir=dist_fep
  ref="com of group Membrane"

  mkwrkdir $workdir
  cd $workdir

  for group in CHOL FepCHOL CHOL_C3 CHOL_C17 FepCHOL_C3 FepCHOL_C17; do
    mkdir -p $group
    select="group $group"
    for l in {0..15}; do
      mkdir -p $group/$l

      distance -s ${fepdir}/lambda${l}/topol.tpr -f ${fepdir}/lambda${l}/traj_comp.xtc -n $index -oxyz $group/$l/xyz.xvg -oz $group/$l/z.xvg -oabsz $group/$l/absz.xvg -ref "$ref" -select "$select"  -seltype "res_com" -dt $dt
      average-xvg.py $group/$l/absz.xvg -o $group/$l/absz_average.xvg

    done

    # all windows to same xvg-file
    find -wholename "./$group/*/z.xvg" | sort -t '/' -k2n | xargs join-xvg.py -o $group/z.xvg -l
    find -wholename "./$group/*/absz.xvg" | sort -t '/' -k2n | xargs join-xvg.py -o $group/absz.xvg -l

  done

  cd ..
}




#----------------------------------------
# MSD (Mean square deviation, diffusion)
msd() {

  # settings
  workdir=msd
  refgroup=Membrane
  trestart=1000
  bf=10000
  ef=20000
  boxsizefile=box/box_ee.xvg
  membrane_center=$(boxcenter $boxsizefile)

  mkwrkdir $workdir
  cd $workdir

  # index files for leaflets
  ndx_leaflets.sh -s $structure -n $index -b $membrane_center

  lastframe=$(timestamp $traj)
  for group in CHOL POPC LBPA DPPC SM16 CERA POPC_P; do

    if [[ $(grep "\[ $group \]" $index) ]]; then
      mkdir -p $group

      b=0
      while [[ $b -lt $lastframe ]]; do

	if [[ $group != POPC_P ]]; then
	  # MSD of molecules
	  echo "$group $refgroup" | gmx_msd_rmcomm_mol msd -trestart $trestart -lateral z -f $traj -n leaflet_A.ndx -s $structure -b $b -o $group/msd_mol_leaflet_A_b${b}.xvg -mol $group/diff_leaflet_A_b${b}.xvg -beginfit $bf -endfit $ef -rmcomm 
	  echo "$group $refgroup" | gmx_msd_rmcomm_mol msd -trestart $trestart -lateral z -f $traj -n leaflet_B.ndx -s $structure -b $b -o $group/msd_mol_leaflet_B_b${b}.xvg -mol $group/diff_leaflet_B_b${b}.xvg -beginfit $bf -endfit $ef -rmcomm 
	  # combine diffusion coefficient files of leaflets
	  xvg_cat.py -f $group/diff_leaflet_A_b${b}.xvg $group/diff_leaflet_B_b${b}.xvg -o $group/diff_b${b}.xvg
	fi

	# MSD of atoms
	echo "$group $refgroup" | gmx msd -trestart $trestart -lateral z -f $traj -n leaflet_A.ndx -s $structure -b $b -o $group/msd_atom_leaflet_A_b${b}.xvg -beginfit $bf -endfit $ef -rmcomm 
	echo "$group $refgroup" | gmx msd -trestart $trestart -lateral z -f $traj -n leaflet_B.ndx -s $structure -b $b -o $group/msd_atom_leaflet_B_b${b}.xvg -beginfit $bf -endfit $ef -rmcomm 

	let b=$b+$block
      done
    fi

  done

  cd ..
}



#---------------------------------
# Density map (normal simulation)
densmap() {

  # settings
  workdir=densmap_b$block

  mkwrkdir $workdir
  cd $workdir

  lastframe=$(timestamp $traj)

  for group in POPC_P CHOL_C3 CHOL_C17 FepCHOL_C3 FepCHOL_C17; do
    if ! [[ $(grep "\[ $group \]" $index) ]]; then
      continue
    fi

    mkdir -p $group
    cd $group

    b=1
    while [[ $b -lt $lastframe ]]; do
      mkdir -p $b
      cd $b

      echo $group | gmx densmap -f $traj -s $structure -n $index -b $b -bin 0.2 -unit nm-2 -o densmap.xpm -dt $dt
      gmx xpm2ps -f densmap.xpm -rainbow blue -o densmap.eps -title none -size 250

      cd ..
      let b=$b+$block
    done

    cd ..
  done

  cd ..
}



#-------------------------------
# Density map (FEP simulations)
densmap_fep() {

  # settings
  workdir=densmap_fep

  mkwrkdir $workdir
  cd $workdir

  # last frame
  lastframe=$(timestamp ${fepdir}/lambda0/traj_comp.xtc)
  echo $lastframe

  for group in POPC_P CHOL_C3 CHOL_C17 FepCHOL_C3 FepCHOL_C17; do
    if ! [[ $(grep "\[ $group \]" $index) ]]; then
      continue
    fi

    mkdir -p $group
    cd $group

    for l in {0..15}; do
      mkdir -p $l
      cd $l

      b=1
      while [[ $b -lt $lastframe ]]; do
	mkdir -p $b
	cd $b

	echo $group | gmx densmap -f ${fepdir}/lambda${l}/traj_comp.xtc -s ${fepdir}/lambda${l}/topol.tpr -n $index -b $b -bin 0.2 -unit nm-2 -o densmap.xpm -dt $dt
	gmx xpm2ps -f densmap.xpm -rainbow blue -o densmap.eps -title none -size 250

	cd .. #b
	let b=$b+$block
      done

      cd .. #l
    done

    cd .. #group
  done

  cd .. # workdir
}


#----------
# Contacts
contacts() {

  # settings
  workdir=contacts
  distance=0.6
  refgroup=CHOL
  groups=(POPC DPPC CERA SM16 LBPA Water)

  mkwrkdir $workdir
  cd $workdir

  for group in ${groups[@]}; do
    if ! [[ $(grep "\[ $group \]" $index) ]]; then
      continue
    fi

    echo "$refgroup $group" | sem -j 6 gmx mindist -f $traj -n $index -s $structure -on numcount_r${distance}_$group -od mindist_r{$distance}_$group -d $distance -dt $dt

  done

  cd ..
}


#------------------------------------
# RDF (Radial distribution function)
rdf() {

  # settings
  workdir=rdf_b$block
  bin=0.02
  refgroup=CHL1
  groups=(POPC DPPC CERA SM16 LBPA)
  if [[ -e box/box_ee.xvg ]]; then
    boxsizefile=box/box_ee.xvg
  else
    boxsizefile=../../../analys/box/box_ee.xvg
  fi
  membrane_center=$(boxcenter $boxsizefile)


  mkwrkdir $workdir
  cd $workdir

  for group in ${groups[@]}; do
    if ! [[ $(grep "\[ $group \]" $index) ]]; then
      continue
    fi

    mkdir -p $group
    cd $group

    lastframe=$(timestamp $traj)
    echo "Last frame: $lastframe"

    # leaflet A
    leaflet="A"
    ref="resname $refgroup and z < $membrane_center"
    sel="resname $group and z < $membrane_center"
    cmd="gmx rdf -f $traj -n $index -s $structure -bin $bin -ref \"$ref\" -sel \"$sel\" -xy -o rdf_leaflet_${leaflet}.xvg -dt $dt -selrpos mol_com"
    block_average "$cmd" $lastframe

    # leaflet B
    leaflet="B"
    ref="resname $refgroup and z > $membrane_center"
    sel="resname $group and z > $membrane_center"
    cmd="gmx rdf -f $traj -n $index -s $structure -bin $bin -ref \"$ref\" -sel \"$sel\" -xy -o rdf_leaflet_${leaflet}.xvg -dt $dt -selrpos mol_com"
    block_average "$cmd" $lastframe

    cd ..

  done

  cd ..
}


#--------
# H-bonds
hbond() {

  # settings
  workdir=hbond
  refgroup=CHOL
  groups=(POPC DPPC CERA SM16 LBPA)

  mkwrkdir $workdir
  cd $workdir

  for group in ${groups[@]}; do
    if ! [[ $(grep "\[ $group \]" $index) ]]; then
      continue
    fi

    echo "$refgroup $group" | gmx hbond -f $traj -n $index -s $structure -dt $dt -num $refgroup-$group.xvg

  done

  cd ..
}

#-----------------------------
# H-bonds per functional group
hbond_group() {

  # settings
  workdir=hbond_group
  refgroup=CHOL
  groups=(POPC DPPC CERA SM16 LBPA)

  mkwrkdir $workdir
  cd $workdir

  # create hbond.ndx
  system_groups=""
  for group in ${groups[@]}; do
    if [[ $(grep "\[ $group \]" $index) ]]; then
      system_groups="$system_groups $group"
    fi
  done
  /mount/wrk/mikkolah/lysosome/scripts/select_hbond.py -s $structure -n hbond.ndx -r $system_groups

  # gmx-hbond
  for group in $(grep "\[" hbond.ndx | awk '{print $2}') ; do
    echo $refgroup $group
    echo "$refgroup $group" | gmx hbond -f $traj -n hbond.ndx -s $structure -dt $dt -num $refgroup-$group.xvg
  done

  cd ..
}

#####################
# Run main function #
#####################
main
