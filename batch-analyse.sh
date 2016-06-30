#!/bin/bash

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
\torder \n
\trms \n
\tsas \n
\tbox \n
\tdensity \n
\tbar \n
\tdist \n
\tdist_fep \n
\tmsd\n
\tdensmap \n
\tdensmap_fep \n
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
    order|rms|sas|box|density|bar|dist|dist_fep|msd|densmap|densmap_fep|rdf)
      tasks+=("$1")
      ;;
    *)
      echo -e $usage
      exit 2
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
  cptfile=$1
  tmax_decimal=$(gmx check -f $cptfile  2>&1 | grep "Last frame" | awk '{print $NF}')
  tmax=$(echo $tmax_decimal/1 | bc) # decimal to integer
  echo $tmax
}





########
# RMSD #
########
rms() {

  # settings
  ref_group="Membrane"
  group_list=("CHOL" "POPC" "LBPA" "CERA" "SM16")
  workdir=rms

  mkdir -p $workdir
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
  echo "$ref_group $groups" | sem -j $maxjobs gmx rms -f $traj -n $index -s $structure -ng $ng -what rmsd  -dt $dt 

  cd ..
}



###################
# ORDER PARAMETER #
###################


order() {

  # settings
  tailnames=("POPC_SN1" "POPC_SN2" "DPPC_SN1" "DPPC_SN2" "SM16_1" "SM16_2")
  workdir=order
  block=10000
  lastframe=$(timestamp $traj)

  mkdir -p $workdir
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
      select="$select name $atom and resname $resname;"
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
  group_list=(POPC DPPC CERA LBPA SM16 CHOL Membrane)
  ref_group="Membrane"
  workdir=sas

  mkdir -p $workdir
  cd $workdir

  for group in  ${groups[@]}; do
    if [[ $(grep " $group " $index) ]]; then
      # gmx sasa
      sem -j $maxjobs gmx sasa -f $traj -n $index -s $structure -o $group-area.xvg -or $group-resarea.xvg -oa $group-atomarea.xvg -tv $group-volume.xvg -q $group-connelly.pdb -surface $ref_group -output $group  -dt 1000 
    fi
  done

  cd ..
}





#######
# BOX #
#######
box() {
  echo -e "Box-X\n Box-Y\n Box-Z" | gmx energy -f $edr -o box.xvg 
}





###########
# DENSITY #
###########
density() {

  # settings
  ref_group="Membrane"
  group_list=("POPC" "CHOL" "CHOL_C3" "CHOL_C17" "LBPA" "CERA" "SM16")
  workdir=gmx density
  sl=100 #slices
  dens="number"

  mkdir -p $workdir
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

  # gmx density
  echo "$ref_group $groups" | sem -j $maxjobs gmx density -f $traj -s $structure -center -n $index -ng $ng -b $begin -symm -sl $sl -dens $dens -o density_sl${sl}_${dens}.xvg
 
  cd ..
}



#######
# BAR #
#######
bar() {

  # settings
  workdir=bar
  temp=310
  b=1
  tstep=2000

  mkdir -p $workdir
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
  while [[ $b -lt $tmax ]]; do

    let e=$b+$tstep-1
    for E in $tmax $e; do 
      sem -j $maxjobs gmx bar -f $dhdl -o bar_$b-$E -oi barint_$b-$E -oh histogram_$b-$E -b $b -e $E 
    done
    let b=$b+$tstep

  done

  # wait until other jobs finish
  sem --wait

  # join
  ls  barint_*000.xvg | sort -t _ -k2n | xargs join-xvg.py -l -o barint_blocks.xvg
  ls  barint_*${tmax}.xvg | sort -t _ -k2n | xargs join-xvg.py -l -o barint.xvg

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

  mkdir -p $workdir
  cd $workdir

  for group in CHOL FepCHOL CHOL_C3 CHOL_C17 FepCHOL_C3 FepCHOL_C17; do
    mkdir -p $group
    select="group $group"

    distance -s $structure -f $traj -n $index -oxyz $group/xyz.xvg -oz $group/z.xvg -oabsz $group/absz.xvg -ref "$ref" -select "$select"  -seltype "res_com"

    average-xvg.py $group/absz.xvg -o $group/absz_average.xvg
  done
  cd ..
}


dist_fep() {

  # settings
  workdir=dist_fep
  ref="com of group Membrane"

  mkdir -p $workdir
  cd $workdir

  for group in CHOL FepCHOL CHOL_C3 CHOL_C17 FepCHOL_C3 FepCHOL_C17; do
    mkdir -p $group
    select="group $group"
    for l in {0..15}; do
      mkdir -p $group/$l

      distance -s ${fepdir}/lambda${l}/topol.tpr -f ${fepdir}/lambda${l}/traj_comp.xtc -n $index -oxyz $group/$l/xyz.xvg -oz $group/$l/z.xvg -oabsz $group/$l/absz.xvg -ref "$ref" -select "$select"  -seltype "res_com"
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

  mkdir -p $workdir
  cd $workdir
  for group in CHOL POPC LBPA DPPC SM16 CERA; do

    echo $group
    if [[ $(grep "\[ $group \]" $index) ]]; then
      mkdir -p $group
      echo "$group" | sem -j $maxjobs gmx msd -trestart 100 -lateral z -f $traj -n $index -s $structure -b $begin -o $group/msd_b${begin}.xvg -mol $group/diff_b${begin}
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

  mkdir -p $workdir
  cd $workdir

  for group in POPC CHOL CERA SM16 LBPA FepCHOL CHOL_C3 CHOL_C17 FepCHOL_C3 FepCHOL_C17; do
    echo $group | gmx densmap -f $traj -s $structure -n $index -b $begin -bin 0.2 -unit nm-2 -o $group.xpm #-od $group.dat
    gmx xpm2ps -f $group.xpm -rainbow blue -o $group.eps
  done

  cd ..
}



densmap_fep() {

  # settings
  workdir=densmap_fep

  mkdir -p $workdir
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
      echo $group | gmx densmap -f ${fepdir}/lambda${l}/traj_comp.xtc -s ${fepdir}/lambda${l}/topol.tpr -n $index -b $begin -bin 0.2 -unit nm-2 -o $group/$l/$b-$e.xpm #-od $group.dat
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

  mkdir -p $workdir
  cd $workdir

  for group in ${groups[@]}; do
    if [[ $(grep "\[ $group \]" $index) ]]; then
      echo "$refgroup $group" | sem -j 6 gmx mindist -f $traj -n $index -s $structure -on numcount_$group -od mindist_$group -d $distance
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

  mkdir -p $workdir
  cd $workdir

  for group in ${groups[@]}; do
    if [[ $(grep "\[ $group \]" $index) ]]; then
      sem -j 6 gmx rdf -f $traj -b $begin -n $index -s $structure -bin $bin -ref $refgroup -sel $group -xy -o $group.xvg
    fi
  done

  cd ..
}




#####################
# run main function #
#####################
main
