#!/bin/bash
#SBATCH -J gentpr_minim
#SBATCH -n 1
#SBATCH -t 00:05:00


# get 15 different inital states from some trajectory
traj="../../npt/traj_comp.xtc"
tpr="../../npt/topol.tpr"
timestep=2000 	# timestep between states
lasttime=200000 # last frame in trajectory

# input files
mdp="minim.mdp"
top="../topology/topol.top"
ndx="../index.ndx"

for l in {0..15}; do

  mkdir lambda$l

  # Get inital state
  let t=$lasttime-$l*$timestep
  echo "lambda: $l time: $t"
  echo "System" | trjconv -f $traj -s $tpr -dump $t -b $t -o lambda$l/confin.gro

  # Create run input file
  sed "s/init-lambda-state = 0/init-lambda-state = $l/" $mdp > lambda$l/$mdp
  grompp -f lambda$l/$mdp -c lambda${l}/confin.gro -p $top -n $ndx -o lambda$l/topol.tpr -po lambda$l/mdout.mdp
done

