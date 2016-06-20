#!/bin/bash -l
#SBATCH -J minim
#SBATCH --array=0-15
#SBATCH -p fys-cpl3
#SBATCH -t 00:15:00
#SBATCH -N 1
#SBATCH --ntasks-per-node=24
#SBATCH --no-requeue
#SBATCH --mail-type=ALL
#SBATCH --mail-user=heikki.mikkolainen@tut.fi

module load gromacs-tut/5.1.2-avx

cd lambda${SLURM_ARRAY_TASK_ID}
mpirun mdrun_mpi -maxh 0.25 -dlb yes -cpi
