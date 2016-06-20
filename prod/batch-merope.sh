#!/bin/bash -l
#SBATCH -J prod
#SBATCH -p fys-cpl3
#SBATCH -t 12:00:00
#SBATCH -N 12
#SBATCH --ntasks-per-node=24
#SBATCH --no-requeue
#SBATCH --mail-type=ALL
#SBATCH --mail-user=heikki.mikkolainen@tut.fi

module load gromacs-tut/5.1.2-avx

mpirun mdrun_mpi -maxh 12 -dlb yes -cpi -replex 500 -multidir lambda0 lambda1 lambda2 lambda3 lambda4 lambda5 lambda6 lambda7 lambda8 lambda9 lambda10 lambda11 lambda12 lambda13 lambda14 lambda15
