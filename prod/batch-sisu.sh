#!/bin/bash -l
#SBATCH -J prod
#SBATCH -p small
#SBATCH -t 5:00:00
#SBATCH -N 16
#SBATCH --ntasks-per-node=24
#SBATCH --no-requeue
#SBATCH --mail-type=ALL
#SBATCH --mail-user=heikki.mikkolainen@tut.fi

#module load gromacs/5.0.5
#module load gromacs/5.1.1
#mdrun_bin=mdrun_mpi
mdrun_bin=/homeappl/home/mikkolai/appl_sisu/gromacs-5.1.2/bin/mdrun_mpi

export OMP_NUM_THREADS=1
let ncores=$SLURM_NNODES*24

aprun -n $ncores $mdrun_bin -maxh 5 -dlb yes -cpi -replex 500 -multidir lambda{0-15} -npme 4
cp lambda0/md.log $SLURM_JOB_ID.log
