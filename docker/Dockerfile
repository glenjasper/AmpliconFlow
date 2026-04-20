# -----------------------------------------------------------------------------
# Base image with micromamba
# -----------------------------------------------------------------------------
# Base OS:
# - Debian (slim variant, maintained by mambaorg)
#
# Micromamba:
# - Lightweight Conda-compatible package manager
# - Faster and lighter than conda/mamba
# - Designed for containerized workflows (bioinformatics standard)
# - Native compatibility with conda-forge and Bioconda
# -----------------------------------------------------------------------------
FROM mambaorg/micromamba:1.5.0

LABEL maintainer="Glen Jasper"
LABEL description="AmpliconFlow: reproducible and scalable workflow for amplicon sequencing analysis"
LABEL version="1.0.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# System dependencies
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    curl \
    git \
    zlib1g \
    zlib1g-dev \
    libbz2-1.0 \
    libbz2-dev \
    pigz \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY envs/ /envs/

RUN micromamba create -y -n ampliconflow -f /envs/python.yml && \
    micromamba install -y -n ampliconflow -f /envs/vsearch.yml && \
    micromamba install -y -n ampliconflow -f /envs/cutadapt.yml && \
    micromamba install -y -n ampliconflow -f /envs/blast.yml && \
    micromamba install -y -n ampliconflow -f /envs/fastqc.yml && \
    micromamba clean --all --yes

# AmpliconFlow scripts
WORKDIR /opt/ampliconflow
COPY scripts/ scripts/
RUN chmod +x scripts/*.py

ENV PATH="/opt/conda/envs/ampliconflow/bin:/opt/ampliconflow/scripts:${PATH}"

CMD ["bash"]
