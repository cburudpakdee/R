export CUDA_HOME=/usr/local/cuda12.6
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_HOME/lib64/:$CUDA_HOME/lib/:$CUDA_HOME/extras/CUPTI/lib64
sudo apt-get install libopenblas-dev pbzip2
sudo apt-get -y install libcurl4-openssl-dev libssl-dev libxml2-dev
conda create -n h2o4gpuenv -c h2oai -c conda-forge -c rapidsai h2o4gpu-cuda10
#---activate h2o environment
conda activate h2o4gpuenv
#---R
if (!require(devtools)) install.packages("devtools")
devtools::install_github("h2oai/h2o4gpu", subdir = "src/interface_r")
library(reticulate)
library(tidyverse)

# Seeing your enviroments
conda_list()

use_condaenv('/home/deviancedev01/miniforge3/envs/h2o4gpuenv/bin/python')
library(h2o4gpu)

# Setup dataset
x <- iris[1:4]
y <- as.integer(iris$Species) - 1

# Initialize and train the classifier
model <- h2o4gpu.random_forest_classifier() %>% fit(x, y)

# Make predictions
predictions <- model %>% predict(x)
predictions
