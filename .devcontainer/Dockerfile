# Base on the official rocker/rstudio image.
FROM docker.io/rocker/rstudio:4.4

WORKDIR /home/rstudio/project

# Update apt cache, install perl, and clean up.
# The rocker base image requires sudo for apt operations.
RUN sudo apt-get update && \
    sudo apt-get install -y perl && \
    sudo rm -rf /var/lib/apt/lists/*
