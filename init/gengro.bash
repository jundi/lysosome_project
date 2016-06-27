#!/bin/bash

# use different timesteps and residues to produce different inital states for
# FEP+REMD simulations
traj="../../npt/traj_comp.xtc"
tpr="../../npt/topol.tpr"
timesteps=(100000 65000 30000)
residues=(91 92 93 94 95)

l=0
for t in ${timesteps[@]}; do

  mkdir -p $t
  echo "System" | gmx trjconv -f $traj -s $tpr -dump $t -b $t -e $t -o ${t}/original.gro

  for r in ${residues[@]}; do
    gro_reorder_residues.py -f ${t}/original.gro -o ${t}/${r}.gro -r1 ${residues[0]} -r2 $r
    ln -s ${t}/${r}.gro lambda$l.gro
    let l=$l+1
  done

done
