display resize 1000 1000
display resetview
scale to 0.03
display projection Orthographic
color Display {Background} white
display shadows on
display ambientocclusion on
axes location off
rotate x by 270



# delete all representations
set numrep [molinfo top get numreps]
for {set i 0} {$i < $numrep} {incr i} {
  mol delrep top top
}

mol delrep top top

# Hydrogens, oxygens...
mol selection {resname POPC DPPC LBPA SM16 CERA CHL1 and not name "C.*"}
mol color type
mol representation VDW 1.000000 12.000000
mol material AOEdgy
mol addrep top

# CHL1 carbons
mol selection {resname CHL1 and name "C.*"}
mol representation VDW 1.000000 12.000000
mol color colorid 17
mol material AOEdgy
mol addrep top

# POPC carbons
mol selection {resname POPC and name "C.*"}
mol representation VDW 1.000000 12.000000
mol color colorid 2
mol material AOEdgy
mol addrep top

# DPPC carbons
mol selection {resname DPPC and name "C.*"}
mol representation VDW 1.000000 12.000000
mol color colorid 23
mol material AOEdgy
mol addrep top

# CERA carbons
mol selection {resname CERA and name "C.*"}
mol representation VDW 1.000000 12.000000
mol color colorid 12
mol material AOEdgy
mol addrep top

# PSM carbons
mol selection {resname SM16 and name "C.*"}
mol representation VDW 1.000000 12.000000
mol color colorid 11
mol material AOEdgy
mol addrep top

# BMP carbons
mol selection {resname LBPA and name "C.*"}
mol representation VDW 1.000000 12.000000
mol color colorid 31
mol material AOEdgy
mol addrep top

# Water
mol selection {water or resname NA CL}
mol representation quicksurf 1.2 1.0 0.5
mol color colorid 23
mol material GlassBubble
mol addrep top
