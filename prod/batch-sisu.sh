#!/bin/bash -l
#SBATCH -J prod
#SBATCH -p small
#SBATCH -t 5:00:00
#SBATCH -N 16
#SBATCH --ntasks-per-node=24
#SBATCH --no-requeue
#SBATCH --mail-type=ALL
#SBATCH --mail-user=heikki.mikkolainen@tut.fi

module load gromacs/5.1.2

export OMP_NUM_THREADS=2
let ncores=$SLURM_NNODES*24

aprun -j 2 -d 2 -n $ncores $mdrun_bin -maxh 5 -dlb yes -cpi -replex 500 -multidir lambda{0..15} -npme 4
cp lambda0/md.log $SLURM_JOB_ID.log
