#!/bin/bash
#SBATCH -J gentpr_minim
#SBATCH -n 1
#SBATCH -t 00:05:00

# input files
mdp="minim.mdp"
top="../../topology/topol_FEP.top"
ndx="../../index.ndx"

for l in {0..15}; do

  mkdir -p lambda$l

  # Create run input file
  sed "s/init-lambda-state = 0/init-lambda-state = $l/" $mdp > lambda$l/$mdp
  grompp -f lambda$l/$mdp -c lambda${l}/confin.gro -p $top -n $ndx -o lambda$l/topol.tpr -po lambda$l/mdout.mdp

done

