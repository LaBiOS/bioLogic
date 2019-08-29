FROM ubuntu:18.04
MAINTAINER Fabiano Menegidio <fabiano.menegidio@biology.bio.br>

##############################################################################
# Metadata
##############################################################################
LABEL base.image="bioAI:gpu"
LABEL version="1"
LABEL description=""
LABEL website=""
LABEL documentation=""

##############################################################################
# ADD config files
##############################################################################
ADD .config/start.sh /start.sh
ADD .config/start-notebook.sh /usr/local/bin/
ADD .config/jupyter.conf /etc/supervisor/conf.d/jupyter.conf
ADD .config/supervisord.conf /.config/
ADD .config/bashrc/.bashrc $HOME/.bashrc
ADD .config/bashrc/.bash_profile $HOME/.bash_profile

##############################################################################
# ENVs
##############################################################################
ENV DEBIAN_FRONTEND noninteractive
ENV SHELL /bin/bash
ENV HOME /root
ENV CUDA_VERSION 10.0.130
ENV CUDA_PKG_VERSION 10-0=$CUDA_VERSION-1
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.0 brand=tesla,driver>=384,driver<385"
ENV CUDA_PATH /usr/local/cuda/bin
ENV CUDNN_VERSION 7.3.1.20
ENV PYTHON3_VERSION miniconda3-latest
ENV PYTHON2_VERSION miniconda2-latest
ENV JUPYTER_TYPE notebook
ENV JUPYTER_PORT 8888
ENV CONDA_DIR $HOME/.$PYTHON3_VERSION/

##############################################################################
# Repositories
##############################################################################
ENV repconda https://repo.continuum.io/miniconda/${PYTHON3_VERSION}-Linux-x86_64.sh
ENV repdvc https://dvc.org/deb/dvc.list
ENV keynvidia https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
ENV repcuda https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64
ENV repnvidia-ml https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64

##############################################################################
# Install base dependencies
##############################################################################
RUN apt-get update \
    && LIBPNG="$(apt-cache depends libpng-dev | grep 'Depends: libpng' | awk '{print $2}')" \
    && apt-get install -y --allow-unauthenticated \
    --no-install-recommends bash git zip wget libssl1.0.0 \
    ca-certificates locales mlocate debconf curl build-essential \
    curl vim bzip2 sudo automake cmake sed grep x11-utils xvfb openssl \
    libxtst6 libxcomposite1 $LIBPNG stunnel \
    && wget ${repodvc} -O /etc/apt/sources.list.d/dvc.list \
    && apt-get update \
    && apt-get clean && apt-get autoclean && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/ \
    && echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && locale-gen en_US.UTF-8 \
    && dpkg-reconfigure locales \
    && mkdir -p /.config \
    && mkdir -p $HOME/workdir/data \
    && mkdir -p $HOME/workdir/notebooks \
    && mkdir -p /.config/supervisord \
    && chmod +x /start.sh \
    && chmod +x /usr/local/bin/start-notebook.sh \
    && \
    
##############################################################################
# Install Miniconda dependencies
##############################################################################
    wget --quiet ${repconda} \
    && /bin/bash ${PYTHON3_VERSION}-latest-Linux-x86_64.sh -b -p ${CONDA_DIR} \
    && rm ${PYTHON3_VERSION}-Linux-x86_64.sh \
    && conda config --add channels defaults \
    && conda config --add channels conda-forge \
    && conda config --add channels bioconda \
    && conda config --add channels anaconda \
    && conda config --add channels toli \
    && conda config --add channels gregvonkuster \
    && conda config --add channels hcc \
    && pip install scif \
    && conda update --all && conda clean -tipsy \
    && /bin/bash -c "exec $SHELL -l" \
    && /bin/bash -c "source $HOME/.bashrc"

    
EXPOSE 6000
EXPOSE 8888
VOLUME ["$HOME/workdir/data"]
