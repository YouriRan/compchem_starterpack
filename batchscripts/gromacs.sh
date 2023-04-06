#!/bin/bash
#SBATCH --job-name=gromacs
#SBATCH --output=%j.log     
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --partition=gpuGTX
#SBATCH --time=03:00:00
#SBATCH --nodelist=compute-21-1
#SBATCH --gres=gpu:rtx2080:1
#SBATCH --gres-flags=enforce-binding

# set scratch
export TMPDIR=/state/partition1

##################
# spack settings #
##################

source /home/spack-user/spack/share/spack/setup-env.sh

# get latest compiler specs
cp /home/spack-user/.spack/linux/compilers.yaml ~/.spack/linux/compilers.yaml

# load architecture specific gromacs if available, otherwise generic
# load specific version with (@version) or spack hash with gromacs/{tag}
spack load gromacs ^slurm architecture=$(spack arch) || spack load gromacs ^slurm target=x86_64

echo "Using gromacs with path $(which gmx_mpi)"

############
# metadata #
############
pwd; hostname; date
echo "===="
echo "Number of cores/node:$SLURM_CPUS_ON_NODE"
echo "Number of cores/task:$SLURM_CPUS_PER_TASK"

echo "SLURM_JOBID=$SLURM_JOBID"
echo "SLURM_JOB_NODELIST=$SLURM_JOB_NODELIST"
echo "SLURM_NNODES=$SLURM_NNODES "
echo "working directory= $SLURM_SUBMIT_DIR "
echo "tmp directory=$TMPDIR"
echo "NPROCS=$SLURM_NPROCS"
echo "Number of CPUs per task=$SLURM_CPUS_PER_TASK"
echo "Count of processors avaiable to the job on this node=$SLURM_JOB_CPUS_PER_NODE"
echo "Number of CPUs requested per allocated GPU=$SLURM_CPUS_PER_GPU"
echo "Number of GPUs requested=$SLURM_GPUS"
echo "Number of tasks=$SLURM_NTASKS"

#######
# run #
#######

# no coredumps
ulimit -S -c 0
ulimit -s unlimited
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# make working directory on compute node
mkdir -p $TMPDIR/$USER/$SLURM_JOBID
cp -rf $SLURM_SUBMIT_DIR/* $TMPDIR/$USER/$SLURM_JOBID
cd $TMPDIR/$USER/$SLURM_JOBID

# run executables
srun --mpi=pmix gmx_mpi mdrun -deffnm nvt 

# copy data to head node and clean
mkdir -p $SLURM_SUBMIT_DIR/result-$SLURM_JOBID
cp -rf $TMPDIR/$USER/$SLURM_JOBID/* $SLURM_SUBMIT_DIR/result-$SLURM_JOBID
rm -rf $TMPDIR/$USER/$SLURM_JOBID

exit