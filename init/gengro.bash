#!/bin/bash
#SBATCH -J gengro
#SBATCH -n 1
#SBATCH -t 00:05:00


# get different states from some trajectory
traj="../../npt/traj_comp.xtc"
tpr="../../npt/topol.tpr"
timestep=10000 	# timestep between states
firstframe=20000 # last frame in trajectory
lastframe=100000 # last frame in trajectory

t=$firstframe
while [[ $t -lt $lastframe ]]; do

  let t=$t+$timestep
  echo "System" | gmx trjconv -f $traj -s $tpr -dump $t -b $t -e $t -o ${t}ps.gro

done
