#!/bin/bash -l
#SBATCH -J prod
#SBATCH -p fys-cpl3
#SBATCH -t 12:00:00
#SBATCH -N 16
#SBATCH --ntasks-per-node=24
#SBATCH --no-requeue
#SBATCH --mail-type=ALL
#SBATCH --mail-user=heikki.mikkolainen@tut.fi

module load gromacs-tut/5.1.2-avx

export OMP_NUM_THREADS=1

mpirun gmx_mpi mdrun -maxh 12 -dlb yes -cpi -replex 500 -multidir lambda{0..15} -npme 4
