FROM ubuntu:22.04

LABEL maintainer="Glen Jasper"
LABEL description="AmpliconFlow: reproducible and scalable workflow for amplicon sequencing analysis"
LABEL version="1.0.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    curl \
    git \
    zlib1g \
    zlib1g-dev \
    libbz2-1.0 \
    libbz2-dev \
    python3 \
    python3-pip \
    vsearch \
    cutadapt \
    fastqc \
    ncbi-blast+ \
    pigz \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3 /usr/bin/python || true

# Python dependencies
COPY docker/requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# AmpliconFlow scripts
WORKDIR /opt/ampliconflow
COPY scripts/ scripts/
RUN chmod +x scripts/*.py

ENV PATH="/opt/ampliconflow/scripts:${PATH}"

CMD ["bash"]
