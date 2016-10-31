#!/bin/bash
set -e

# use different timesteps and residues to produce different inital states for
# FEP+REMD simulations
traj="../../../../npt/traj_comp.xtc"
tpr="../../../../npt/topol.tpr"
timesteps=(500000 400000 300000 200000)
fep_residue=91
residues=(96 97 98 99 100)

l=0
for t in ${timesteps[@]}; do

  mkdir -p $t
  echo "System" | gmx trjconv -f $traj -s $tpr -dump $t -b $t -e $t -o ${t}/original.gro

  for r in ${residues[@]}; do
    gro_reorder_residues.py -f ${t}/original.gro -o ${t}/${r}.gro -r1 $fep_residue -r2 $r
    ln -s ${t}/${r}.gro lambda$l.gro
    let l=$l+1
  done

done
