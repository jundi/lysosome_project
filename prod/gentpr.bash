#!/bin/bash
#SBATCH -J gentpr_prod
#SBATCH -n 1
#SBATCH -t 00:05:00

mdp="prod.mdp"
top="../topology/topol.top"
ndx="../index.ndx"
confdir="../minim/"

for l in {0..15}; do
  mkdir lambda$l
  sed "s/init-lambda-state = 0/init-lambda-state = $l/" $mdp > lambda$l/$mdp
  grompp -f lambda$l/$mdp -c ${confdir}/lambda${l}/confout.gro -p $top -n $ndx -o lambda$l/topol.tpr -po lambda$l/mdout.mdp
done

