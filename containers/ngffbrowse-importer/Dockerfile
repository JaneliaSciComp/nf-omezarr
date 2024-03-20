# Create final image
FROM condaforge/mambaforge as builder

RUN mamba create -n myenv -c conda-forge python=3.10 zarr=2.17.* -y \
    && mamba clean --tarballs -y \
    && mkdir -p /opt/conda/envs/myenv/etc/conda/activate.d \
    # It's necessary to set TMPDIR for running with Singularity, because /opt/conda will be read-only
    && echo "export TMPDIR=/tmp" > /opt/conda/envs/myenv/etc/conda/activate.d/env_vars.sh

WORKDIR /app

# ps is needed by nextflow to collect task metrics
RUN apt-get install -y procps \
    && echo "0.0.1" > /app/VERSION

COPY scripts /app

RUN echo "#!/bin/bash" >> /app.sh \
    && echo "source /opt/conda/etc/profile.d/conda.sh" >> /app.sh \
    && echo "SCRIPT_NAME=\$1; shift" >> /app.sh \
    && echo "conda activate myenv" >> /app.sh \
    && echo 'python /app/${SCRIPT_NAME}.py "$@"' >> /app.sh \
    && chmod +x /app.sh
