#!/bin/bash -l
#SBATCH -J minim
#SBATCH --array=0-15
#SBATCH -p short
#SBATCH -t 00:15:00
#SBATCH -N 1
#SBATCH --ntasks-per-node=12
#SBATCH --no-requeue
#SBATCH --mail-type=ALL
#SBATCH --mail-user=heikki.mikkolainen@tut.fi

cd lambda${SLURM_ARRAY_TASK_ID}

/fys/mikkolah/.local/gromacs-5.1.2/bin/gmx mdrun -maxh 0.25 -dlb yes -cpi
