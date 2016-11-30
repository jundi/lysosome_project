#traj=../../npt/traj_0ns-500ns_dt1000.xtc
traj=test.xtc
tpr=../../npt/topol.tpr
ndx=../../index.ndx
g1="vector"

boxsize=3.9
last_resid=15
sep=" or "
resid=1
group1=""
while [[ $resid -le $last_resid ]]; do
  group1="${group1}(name P and (z >= $boxsize) and resname SM16 and resid $resid) or (name N and (z >= $boxsize) and resname SM16 and resid $resid) or (name N and (z < $boxsize) and resname SM16 and resid $resid) or (name P and (z < $boxsize) and resname SM16 and resid $resid)" 
  if [[ $resid -lt $last_resid ]];then
    group1="${group1}$sep" 
  fi
  let resid=$resid+1
done

echo -e $group1

gmx gangle -f $traj -s $tpr -n $ndx  -g1 $g1 -group1 "$group1" -g2 z -oav -oall -oh 
