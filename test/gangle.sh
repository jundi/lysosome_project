#!/bin/bash
set -e

traj=../../npt/traj_0ns-500ns_dt1000.xtc
#traj=../../npt/traj_0ns-500ns_dt100.xtc
tpr=../../npt/topol.tpr
ndx=../../index.ndx
g1="vector"
boxsize=3.9
last_resid=30
first_resid=1
sep=" ; "

resid=1
group1=""
while [[ $resid -le $last_resid ]]; do

  group1="$group1(name P and resid $resid and z >= $boxsize) plus (name N and resid $resid and z >=$boxsize) plus (name N and resid $resid and z < $boxsize) plus (name P and resid $resid and z < $boxsize)" 

  if [[ $resid -lt $last_resid ]];then
    group1="${group1}$sep" 
  fi

  let resid=$resid+1

done

gmx select -s $tpr -on ndx.ndx -select "$group1"



groups="group 0"
n=1
let ngroups=$last_resid-$first_resid
echo $ngroups
while [[ $n -lt $last_resid ]]; do
  groups="$groups plus group $n"
  let n=$n+1
done

gmx gangle -f $traj -s $tpr -n ndx.ndx -g1 $g1 -g2 z -oav -oall -oh -group1 "$groups"
