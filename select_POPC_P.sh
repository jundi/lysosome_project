#!/bin/bash
set -e

for d in  60POPC_10CHOL_30CERA 60POPC_10CHOL_30DPPC 60POPC_10CHOL_30SM16 74POPC_10CHOL_16LBPA22RR 74POPC_10CHOL_16LBPA22SS 90POPC_10CHOL; do
  cd $d

  cp index.ndx index_backup.ndx
  gmx select -n index.ndx -s npt/topol.tpr -select "resname POPC and name P" -on POPC_P.ndx
  sed -i 's/resname_POPC_and_name_P/POPC_P/' POPC_P.ndx
  cat POPC_P.ndx >> index.ndx
  rm POPC_P.ndx

  cd -
done
