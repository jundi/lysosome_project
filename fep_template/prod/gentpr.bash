#!/bin/bash

# input files
mdp="prod.mdp"
top="../../topology/topol_FEP.top"
ndx="../../index.ndx"
confdir="../minim/"

for l in {0..15}; do
  mkdir -p lambda$l
  sed "s/init-lambda-state	= 0/init-lambda-state	= $l/" $mdp > lambda$l/$mdp
  gmx grompp -f lambda$l/$mdp -c ${confdir}/lambda${l}/confout.gro -p $top -n $ndx -o lambda$l/topol.tpr -po lambda$l/mdout.mdp
done

