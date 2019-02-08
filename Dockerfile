FROM ubuntu:16.04

# Install packages
RUN apt-get -qq update && \
    apt-get install -qq -y \
    apt-transport-https \
    apt-utils \
    bzip2 \
    ca-certificates \
    cmake \
    curl \
    gcc \
    gfortran \
    git \
    gnupg2 \
    g++ \
    hdf5-tools \
    libgl1-mesa-glx \
    libopenmpi-dev \
    make \
    slurm-client \
    software-properties-common \
    vim \
    wget && \
    apt-get -qq -y autoremove && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* /var/log/dpkg.log 

# Set up conda (for python postprocessing):
ENV PATH /usr/local/bin:$PATH
RUN curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -bfp /usr/local && \
    rm -rf /tmp/miniconda.sh && \
    conda update -q conda && \
    conda clean -aq && \
    ln -s /usr/local/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /usr/local/etc/profile.d/conda.sh" >> ~/.bashrc

# Install MKL
RUN curl -sSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB -o /tmp/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    apt-key add /tmp/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    sh -c 'echo deb https://apt.repos.intel.com/mkl all main > /etc/apt/sources.list.d/intel-mkl.list' && \
    apt-get -qq -y update && \
    apt-get install -qq -y intel-mkl-64bit-2019.1 


# Set the working directory to /app
WORKDIR /app
# Set up python environment... this takes awhile:
COPY . dockerfiles/
RUN conda config --set always_yes yes --set changeps1 no && \
    conda env create -v -q -n py36 -f ./dockerfiles/env36.yml && \
    conda clean -aq && \
    echo "conda activate py36" >> ~/.bashrc
ENV PATH /usr/local/envs/py36/bin:$PATH
# Expose 8888 for jupyter notebook
EXPOSE 8888

# Add a testuser to execute make test (openmpi doesn't like mpiexec from root)
RUN adduser --disabled-password --gecos "" --quiet testuser && \
    chmod -R u+rwx /app 

# Install ALPSCore
RUN apt-get install -y -qq libboost-filesystem-dev libhdf5-dev 
RUN curl -sSL https://github.com/ALPSCore/ALPSCore/archive/v2.3.0-rc.1.tar.gz -o /tmp/alpscore.tar.gz && \
    mkdir -p alpscore && \
    tar -xzf /tmp/alpscore.tar.gz -C alpscore --strip-components 1 && \
    mkdir -p alpscore_build && \
    cd alpscore_build && \
    cmake ../alpscore \
          -DALPS_INSTALL_EIGEN=ON \
          -DCMAKE_INSTALL_PREFIX="/usr/local" \
          -DCMAKE_BUILD_TYPE="Release" \
          -DTesting="OFF" && \
    make -j4 && \
    make install && \
    cd .. && \
    rm -rf alpscore_build alpscore

# Install CT-HYB
RUN curl -sSL https://github.com/ALPSCore/CT-HYB/archive/v1.0.3.tar.gz -o /tmp/ct-hyb.tar.gz && \
    mkdir -p ct-hyb && \
    tar -xzf /tmp/ct-hyb.tar.gz -C ct-hyb --strip-components 1 && \
    mkdir -p ct-hyb_build && \
    cd ct-hyb_build && \
    cmake ../ct-hyb \
        -DCMAKE_INSTALL_PREFIX="/usr/local" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DTesting="OFF" && \
    make -j4 && \
    make install && \
    cd .. && \ 
    rm -rf ct-hyb-build ct-hyb

# Install TRIQS
#RUN curl -sSL https://users.flatironinstitute.org/~ccq/triqs/xenial/public.gpg | apt-key add - && \
#    add-apt-repository "deb https://users.flatironinstitute.org/~ccq/triqs/xenial/ /" && \
#    apt-get -qq -y update && \
#    apt-get install -y -qq triqs
#
# Install TRIQS development
#RUN curl -sSL https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
#    add-apt-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-6.0 main" -y && \
#    apt-get install -y -qq clang-6.0 libclang-6.0-dev python-clang-6.0 && \
#ENV LIBCLANG_LOCATION /usr/lib/llvm-6.0/lib/libclang.so
#ENV LIBCLANG_CXX_FLAGS="-I/usr/include/x86_64-linux-gnu/c++/7" && \
#ENV CPLUS_INCLUDE_PATH=/usr/include/openmpi:/usr/include/hdf5/serial/:$CPLUS_INCLUDE_PATH

# gftools
RUN apt-get install -y -qq libfftw3-dev
RUN git clone https://github.com/aeantipov/gftools.git 
RUN git clone https://github.com/aeantipov/opendf.git && \
    mkdir -p opendf_build && \
    cd opendf_build && \
    cmake ../opendf \
        -DCMAKE_INSTALL_PREFIX="/usr/local" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DTesting="ON" \
        -DGFTOOLS_INCLUDE_DIR="/app/gftools" \
        -DAutoSetCXX11="OFF" && \ 
    make -j4 && \
    make install && \
    cd ..
    #su testuser -c "ctest" testuser && \

# Pomerol
RUN apt-get install -y -qq libboost-serialization-dev libboost-mpi-dev
RUN git clone https://github.com/aeantipov/pomerol.git && \
    mkdir -p pomerol_build && \
    cd pomerol_build && \
    cmake ../pomerol \
        -DCMAKE_INSTALL_PREFIX="/usr/local" \
        -DEIGEN3_INCLUDE_DIR="/usr/local/deps/eigen" \
        -DCMAKE_BUILD_TYPE="Release" \
        -DTesting="ON" \
        -DPOMEROL_COMPLEX_MATRIX_ELEMENTS="ON" \
        -DGFTOOLS_INCLUDE_DIR="/app/gftools" \
        -DCXX11="ON" \ 
        -DPOMEROL_BUILD_STATIC=OFF 
#&& \
#    make -j4 && \
#    make install && \
#    cd ..
    #su testuser -c "ctest" testuser && \
    
