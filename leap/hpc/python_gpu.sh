#!/bin/bash
#SBATCH --time=4:00:00
#SBATCH --mem=128000
#SBATCH -N 1
#SBATCH --cpus-per-task=4
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks-per-socket=1
#SBATCH --gres=gpu:1

echo "args: ${@:1}"

python ${@:1}
