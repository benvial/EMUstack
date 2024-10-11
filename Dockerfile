
FROM ubuntu:latest
SHELL ["/bin/bash", "-c"]
RUN apt-get update && apt-get install -y --no-install-recommends  \
    python3-full python3-pip python3-dev gfortran make pkg-config cmake \
    libsuitesparse-dev liblapack-dev libopenblas-dev && \
    rm -rf /var/lib/apt /var/lib/dpkg /var/lib/cache /var/lib/log;
COPY ./ /home/EMUstack/

WORKDIR /home/EMUstack
RUN python3 -m venv .venv && . .venv/bin/activate && pip install .

WORKDIR /home
RUN mkdir host

ENV OPENBLAS_NUM_THREADS=1
ENV OMP_NUM_THREADS=1

RUN echo -e ". /home/EMUstack/.venv/bin/activate" >> ~/.bashrc
RUN . ~/.bashrc