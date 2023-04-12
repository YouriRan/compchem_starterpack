#!/bin/bash
#SBATCH --job-name=basic
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
export WORKDIR=${TMPDIR}/$USER/$SLURM_JOBID
export RESULTSDIR=$SLURM_SUBMIT_DIR/$SLURM_JOBID

# set omp threads
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

##################
# spack settings #
##################

source /home/spack-user/spack/share/spack/setup-env.sh

# get latest compiler specs
cp /home/spack-user/.spack/linux/compilers.yaml ~/.spack/linux/compilers.yaml
# spack load 

###################################
# epilogue and prologue functions #
###################################

# these functions only work for single node jobs
# for multi-node jobs, please edit script such that a scratch is made on every node

prologue()
{
    # make scratch directory
    mkdir -p $WORKDIR
    # copy files to scratch directory
    cp -rf $SLURM_SUBMIT_DIR/* $WORKDIR
    cd $WORKDIR
}

# copies all files from scratch dir to submit directory. Does not remove data unless copy 
epilogue()
{   
    # make results directory
    mkdir -p $RESULTSDIR
    # copy files and only delete if copy works, else notify
    cp -r $WORKDIR/* $RESULTSDIR && rm -rf $WORKDIR
}

##################
# print metadata #
##################

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

# no coredumps (from Mahdi's script, what does this do?)
ulimit -S -c 0
ulimit -s unlimited

# run prologue
prologue

# run epilogue when shell exits (scancel or script finished)
trap "{epilogue; }" EXIT

# run executables
srun --mpi=pmix ./executable -args

# exit (epilogue is ran)
exit