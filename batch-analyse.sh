#!/bin/bash
set -e

#########################
# list of possible tasks
#########################
task_options=(order rms sas box density bar dist dist_fep msd densmap densmap_fep rdf contacts rdf_test)


#########
# manual
#########
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
\t-b \t first frame to use (ps) \n
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
traj=$(readlink -f ../npt/traj_comp.xtc)
structure=$(readlink -f ../npt/topol.tpr)
index=$(readlink -f ../index.ndx)
edr=$(readlink -f ../npt/ener.edr)
fepdir=$(readlink -f ../free_energy/prod)
# other parameters
begin=0   # first timestep to be used
block=10000   # first timestep to be used
dt=-1     # skip frames
maxjobs=4 # max parallel jobs


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
      begin="$2"
      shift
      ;;
    -l)
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



########
# main #
########
main() {

  for task in ${tasks[@]} ;do
    mkdir -p logs
    echo -e "Calculating $task..."
    $task  >"logs/${task}.log" 2> "logs/${task}2.log"
  done

  sem --wait
  echo -e "All tasks completed."

}



#########################
# timestamp of cpt file #
#########################
timestamp() {
  local cptfile=$1
  local tmax_decimal=$(gmx check -f $cptfile  2>&1 | grep "Last frame" | awk '{print $NF}')
  local tmax=$(echo $tmax_decimal/1 | bc) # decimal to integer
  echo $tmax
}



##########################
# make working directory #
##########################
mkwrkdir() {
  local wrkdir=$1
  if [[ -e $wrkdir ]]; then
    mv $wrkdir ${wrkdir}_backup_$(date +"%Y%m%d_%H%M%S")
  fi
  mkdir -p $wrkdir
}


##########################
# block average function #
##########################
block_average() {
  cmd="$1"
  local lastframe="$2"

  echo "$cmd"
  echo "$block"
  echo "$lastframe"

  local blocklist=""
  local b=1
  local e
  let e=$b+$block-1
  while [[ $e -le $lastframe ]]; do 
    blocklist=(${b}-${e} ${blocklist[*]})
    mkdir -p $b-$e
    cd $b-$e

    $cmd -b $b -e $e 

    cd ..
    let b=$b+$block
    let e=$e+$block
  done

  sem --wait
  local xvgfiles=$(find ${blocklist[0]} -name "*.xvg")
  for x in $xvgfiles; do
    local xname=$(basename $x)
    echo $xname
    local filelist=""
    local avg_lastframe=$(echo ${blocklist[0]} | cut -d '-' -f 2)
    echo $avg_lastframe
    for b in ${blocklist[@]}; do
      filelist="$b/${xname} $filelist"
      echo $filelist
      local avg_firstframe=$(echo ${b} | cut -d '-' -f 1)
      echo $avg_firstframe
      if [[ $(echo $filelist | wc -w) -gt 1 ]]; then
	average-xvg.py -o ${avg_firstframe}-${avg_lastframe}_${xname} $filelist
      fi
    done
  done

  join-xvg.py -l -o blocks_${xname} $filelist

}





########
# RMSD #
########
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



###################
# ORDER PARAMETER #
###################


order() {

  # settings
  tailnames=("POPC_SN1" "POPC_SN2" "DPPC_SN1" "DPPC_SN2" "SM16_1" "SM16_2" "CERA_1" "CERA_2" "LBPA_1" "LBPA_2")
  workdir=order
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






########
# SASA #
########
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





#######
# BOX #
#######
box() {

  workdir=box

  mkwrkdir $workdir
  cd $workdir

  echo -e "Box-X\n Box-Y\n Box-Z" | gmx energy -f $edr -o box.xvg 
  xvg_runningmean.py -f box.xvg -n 100

  cd ..
}





###########
# DENSITY #
###########
density() {

  # settings
  ref_group="Membrane"
  groups=("POPC" "CHOL" "CHOL_C3" "CHOL_C17" "LBPA" "CERA" "SM16" "DPPC")
  workdir=density
  sl=100 #slices
  dens="number"

  mkwrkdir $workdir
  cd $workdir


  lastframe=$(timestamp $traj)
  for group in ${groups[@]}; do

    if ! [[ $(grep "\[ $group \]" $index) ]]; then
      continue
    fi

    mkdir -p $group

    b=1
    while [[ $b -lt $lastframe ]]; do
      let e=$b+${block}-1
      mkdir -p $group/$b-$e
      echo "$ref_group $group" | gmx density -f $traj -s $structure -center -n $index -b $b -e $e -symm -sl $sl -dens $dens -o $group/$b-$e/density_sl${sl}_${dens}.xvg -dt $dt
      let b=$b+${block}
    done
    #sem --wait

    # compute averages
    allfiles=$(find $group -name density_sl${sl}_${dens}.xvg | sort -t / -k2nr)
    filelist=""
    for f in $allfiles; do
      filelist="$filelist $f"
      time1=$(echo $f | cut -d "/" -f2 | cut -d "-" -f1)
      time2=$(echo $filelist | cut -d "/" -f2 | cut -d "-" -f2)
      average-xvg.py -o $group/${time1}-${time2}_density_sl${sl}_${dens}.xvg $filelist
    done

    # join blocks to one file
    allfiles=$(find $group -name density_sl${sl}_${dens}.xvg | sort -t / -k2n)
    join-xvg.py -l -o $group/density_sl${sl}_${dens}.xvg $allfiles

  done

  cd ..

}



#######
# BAR #
#######
bar() {

  # settings
  workdir=bar
  temp=310

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

  # BAR
  b=1
  let e=$b+$block-1
  blocklist=""
  while [[ $e -lt $tmax ]]; do

    blocklist="$b-$e/barint.xvg $blocklist"

    for E in $tmax $e; do 
      mkdir -p $b-$E
      sem -j $maxjobs gmx bar -f $dhdl -o $b-$E/bar.xvg -oi $b-$E/barint.xvg -oh $b-$E/histogram.xvg -b $b -e $E 
    done

    let b=$b+$block
    let e=$b+$block-1

  done

  # wait until other jobs finish
  sem --wait

  # join blocks to one file
  join-xvg.py -l -o barint_blocks.xvg $blocklist

  # block average
  filelist=""
  for f in $blocklist; do
    filelist="$filelist $f"
    time1=$(echo $f | cut -f 1 -d '-')
    time2=$(echo $filelist | cut -f 2 -d '-' | cut -d / -f 1)
    average-xvg.py -o barint_${time1}-${time2}.xvg $filelist
  done

  # DEMUX
  demux.pl $fepdir/lambda0/md.log

  cd ..
}


########
# DIST #
########
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




########
# MSD #
########
msd() {

  # settings
  workdir=msd

  mkwrkdir $workdir
  cd $workdir

  lastframe=$(timestamp $traj)
  for group in CHOL POPC LBPA DPPC SM16 CERA; do

    if [[ $(grep "\[ $group \]" $index) ]]; then
      mkdir -p $group

      b=0
      while [[ $b -lt $lastframe ]]; do
	echo "$group" | sem -j $maxjobs gmx msd -trestart 100 -lateral z -f $traj -n $index -s $structure -b $b -o $group/msd_b${b}.xvg -mol $group/diff_b${b} 
	let b=$b+$block
      done
      sem --wait
    fi

  done

  cd ..
}



###############
# DENSITY MAP #
###############
densmap() {

  # settings
  workdir=densmap

  mkwrkdir $workdir
  cd $workdir

  for group in POPC CHOL CERA SM16 LBPA FepCHOL CHOL_C3 CHOL_C17 FepCHOL_C3 FepCHOL_C17; do
    echo $group | gmx densmap -f $traj -s $structure -n $index -b $begin -bin 0.2 -unit nm-2 -o $group.xpm  -dt $dt #-od $group.dat
    gmx xpm2ps -f $group.xpm -rainbow blue -o $group.eps
  done

  cd ..
}



densmap_fep() {

  # settings
  workdir=densmap_fep

  mkwrkdir $workdir
  cd $workdir

  # last frame
  tmax=$(timestamp ${fepdir}/lambda0/state.cpt)
  echo "Last frame = $tmax"

  e=$tmax
  b=$begin
  for group in POPC CHOL CERA SM16 LBPA FepCHOL CHOL_C3 CHOL_C17 FepCHOL_C3 FepCHOL_C17; do
    mkdir -p $group
    for l in {0..15}; do
      mkdir -p $group/$l
      echo $group | gmx densmap -f ${fepdir}/lambda${l}/traj_comp.xtc -s ${fepdir}/lambda${l}/topol.tpr -n $index -b $begin -bin 0.2 -unit nm-2 -o $group/$l/$b-$e.xpm -dt $dt #-od $group.dat
      gmx xpm2ps -f $group/$l/$b-$e.xpm -rainbow blue -o $group/$l/$b-$e.eps
    done
  done

  cd ..
}


############
# CONTACTS #
############
contacts() {

  # settings
  workdir=contacts
  distance=0.2
  refgroup=CHOL
  groups=(POPC DPPC CERA SM16 LBPA)

  mkwrkdir $workdir
  cd $workdir

  for group in ${groups[@]}; do
    if [[ $(grep "\[ $group \]" $index) ]]; then
      echo "$refgroup $group" | sem -j 6 gmx mindist -f $traj -n $index -s $structure -on numcount_$group -od mindist_$group -d $distance -dt $dt
    fi
  done

  cd ..
}


#######
# RDF #
#######
rdf() {

  # settings
  workdir=rdf
  bin=0.02
  refgroup=CHOL
  groups=(POPC DPPC CERA SM16 LBPA)

  mkwrkdir $workdir
  cd $workdir

  for group in ${groups[@]}; do
    if ! [[ $(grep "\[ $group \]" $index) ]]; then
      continue
    fi

    mkdir -p $group

    b=1
    lastframe=$(timestamp $traj)
    blocklist=""
    while [[ $b -lt $lastframe ]]; do

      blocklist="${b} $blocklist"
      let e=$b+${block}-1
      mkdir -p $group/$b-$e

      sem -j 6 gmx rdf -f $traj -b $b -e $e -n $index -s $structure -bin $bin -ref $refgroup -sel $group -xy -o $group/$b-$e/rdf.xvg -dt $dt

      let b=$b+${block}
    done

    # block average
    sem --wait
    filelist=""
    let E=${blocklist[0]}+${block}-1
    for b in $blocklist; do
      let e=$b+${block}-1
      filelist="$filelist $group/$b-$e/rdf.xvg"
      average-xvg.py -o ${group}/${b}-${E}_rdf.xvg $filelist
    done

    # merge blocks to one file
    join-xvg.py -o ${group}/rdf_blocks.xvg $filelist


  done

  cd ..
}


rdf_test() {

  # settings
  workdir=rdf
  bin=0.02
  refgroup=CHOL
  groups=(POPC DPPC CERA SM16 LBPA)

  mkwrkdir $workdir
  cd $workdir

  for group in ${groups[@]}; do
    if ! [[ $(grep "\[ $group \]" $index) ]]; then
      continue
    fi

    mkdir -p $group
    cd $group

    lastframe=$(timestamp $traj)
    cmd="gmx rdf -f $traj -n $index -s $structure -bin $bin -ref $refgroup -sel $group -xy -o rdf.xvg -dt $dt"
    block_average "$cmd" $lastframe

    cd ..

  done

  cd ..
}




#####################
# run main function #
#####################
main
