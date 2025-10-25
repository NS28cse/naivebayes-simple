# Base image Debian 12 slim.
FROM debian:12-slim

# Set working directory.
WORKDIR /app

# Install dependencies for Perl, R, and RStudio Server.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        r-base \
        perl \
        unzip \
        wget \
        gdebi-core \
        sudo \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install fixed version of RStudio Server.
RUN wget https://download2.rstudio.org/server/debian11/amd64/rstudio-server-2023.12.1-402-amd64.deb && \
    gdebi -n rstudio-server-2023.12.1-402-amd64.deb && \
    rm rstudio-server-2023.12.1-402-amd64.deb

# Create a non-root user 'devuser' with password 'devuser'.
RUN useradd --create-home --shell /bin/bash devuser && \
    echo "devuser:devuser" | chpasswd && \
    adduser devuser sudo

# Expose RStudio port.
EXPOSE 8787

# Start RStudio Server.
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize=0"]