FROM ubuntu:latest
USER root
SHELL ["/bin/bash", "-c"]
ENV OPENBLAS_NUM_THREADS=1
ENV OMP_NUM_THREADS=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-full python3-pip python3-dev gcc gfortran make pkg-config cmake \
    libsuitesparse-dev liblapack-dev libopenblas-dev &&  \
    rm -rf /var/lib/apt /var/lib/dpkg /var/lib/cache /var/lib/log
COPY ./ /home/EMUstack/

WORKDIR /home/EMUstack
RUN python3 -m venv .emustack && . .emustack/bin/activate && pip install .

WORKDIR /home

RUN echo -e ". /home/EMUstack/.emustack/bin/activate" >>~/.bashrc
RUN . ~/.bashrc
