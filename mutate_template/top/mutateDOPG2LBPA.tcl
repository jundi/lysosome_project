mol load psf inp/step5_charmm2gmx.psf pdb inp/step5_charmm2gmx.pdb

set popc [atomselect top "resname POPC"]
$popc writepdb popc.pdb
set dopg [atomselect top "resname DOPG"]
$dopg writepdb dopg.pdb
set chl1 [atomselect top "resname CHL1"]
$chl1 writepdb chl1.pdb
set tip3 [atomselect top "segid TIP3"]
$tip3 writepdb tip3.pdb
set sod [atomselect top "segid SOD"]
$sod writepdb sod.pdb
set cla [atomselect top "segid CLA"]
$cla writepdb cla.pdb

package require psfgen 

topology top/top_all36_lipid.rtf
topology top/top_all36_cgenff.rtf
topology top/top_all36_LBPA.rtf
topology top/top_all36_cholesterol.rtf
topology top/top_water_ions.rtf

set dopg_resids [lsort -unique [$dopg get resid]]

segment LBPA {
        pdb dopg.pdb  
	foreach r  $dopg_resids {
	  mutate $r LBPA
        }
}
coordpdb dopg.pdb LBPA

segment POPC {
        pdb popc.pdb  
}
coordpdb popc.pdb POPC

segment CHL1 {
        pdb chl1.pdb  
}
coordpdb chl1.pdb CHL1

segment TIP3 {
	auto none
	pdb tip3.pdb	
}
coordpdb tip3.pdb TIP3

segment SOD {
        auto none 
	pdb sod.pdb	
}
coordpdb sod.pdb SOD

segment CLA {
        auto none 
	pdb cla.pdb	
}
coordpdb cla.pdb CLA

guesscoord 

regenerate angles dihedrals

writepsf DOPG2LBPA.psf
writepdb DOPG2LBPA.pdb

exit
