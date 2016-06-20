#!/bin/bash -l
#SBATCH -J prod
#SBATCH -p small
#SBATCH -t 12:00:00
#SBATCH -N 16
#SBATCH --ntasks-per-node=24
#SBATCH --no-requeue
#SBATCH --mail-type=ALL
#SBATCH --mail-user=heikki.mikkolainen@tut.fi

#module load gromacs/5.0.5
#module load gromacs/5.1.1
export OMP_NUM_THREADS=1

let ncores=$SLURM_NNODES*24
#mdrun_bin=mdrun_mpi
mdrun_bin=/homeappl/home/mikkolai/appl_sisu/gromacs-5.1.2/bin/mdrun_mpi

aprun -n $ncores $mdrun_bin -maxh 12 -dlb yes -cpi -replex 500 -multidir lambda0 lambda1 lambda2 lambda3 lambda4 lambda5 lambda6 lambda7 lambda8 lambda9 lambda10 lambda11 lambda12 lambda13 lambda14 lambda15 
