# Docker image for ACE Game engine

FROM ozzyboshi/bebbo-amiga-gcc:20190715
#FROM bebbotest
MAINTAINER Ozzyboshi <gun101@email.it>

ARG ace_branch=master

# Passare --build-arg ace_releasetype=Debug per avere il debug
ARG ace_releasetype=Release

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -y install cmake wget && rm -rf /var/lib/apt/lists/*

#ilbm2raw
WORKDIR /root
RUN wget 'https://github.com/Ozzyboshi/ilbm2raw/archive/v0.1.tar.gz'
RUN tar -xvzpf v0.1.tar.gz
RUN cd ilbm2raw-0.1/ && ./configure && make && make install

WORKDIR /root

# fmt is needed to get ace tools running
RUN git clone https://github.com/fmtlib/fmt
RUN cd fmt && mkdir build && cd build && cmake .. && make && make install

WORKDIR /root
#RUN git clone https://github.com/AmigaPorts/ACE.git && cd ACE && git checkout ${ace_branch}
RUN git clone https://github.com/Ozzyboshi/ACE.git && cd ACE && git checkout ${ace_branch}
# Copy custom system.c with no sound on intena and 
# COPY system.c /root/ACE/src/ace/managers/system.c
RUN sed -i 's/INTF_PORTS | INTF_AUD0 | INTF_AUD1 | INTF_AUD2 | INTF_AUD3/INTF_PORTS/'  /root/ACE/src/ace/managers/system.c
RUN sed -i 's/s_pHwVectors[SYSTEM_INT_VECTOR_FIRST + i] = s_pAceHwInterrupts[i];/if (i<4) s_pHwVectors[SYSTEM_INT_VECTOR_FIRST + i] = s_pAceHwInterrupts[i];/' /root/ACE/src/ace/managers/system.c

RUN git clone https://github.com/AmigaPorts/AmigaCMakeCrossToolchains.git 

RUN cd ACE/tools && mkdir build
WORKDIR /root/ACE/tools/build
RUN  cmake .. && make

# fix utils path
WORKDIR /root
RUN mkdir ACE/tools/palette_conv && cp ACE/tools/bin/palette_conv /root/ACE/tools/palette_conv/palette_conv
# WORKDIR /root/ACE/tools/bitmap_conv/
# RUN gcc bitmap_conv.c lodepng.c -std=c99 -Wall -o bitmap_conv

WORKDIR /root
RUN cd ACE/ && mkdir build
WORKDIR /root/ACE/build
RUN M68K_TOOLCHAIN_PATH=/bin cmake .. -DCMAKE_TOOLCHAIN_FILE=/root/AmigaCMakeCrossToolchains/m68k-amigaos.cmake -DM68K_TOOLCHAIN_PATH=/opt/amiga -DM68K_CPU=68000 -DM68K_FPU=soft -DCMAKE_BUILD_TYPE=${ace_releasetype}
RUN make

# Copy ace static library
RUN cp /root/ACE/build/libace.a /opt/amiga/m68k-amigaos/lib/

# Copy ace tools
RUN cp /root/ACE/tools/bin/* /usr/local/bin/
# RUN cp /root/ACE/tools/bitmap_conv/bitmap_conv /usr/local/bin/

# Copy incbin
COPY incbin.sh /usr/local/bin/

# Copy exe2adf
COPY exe2adf-linux64bit /usr/local/bin/

# solo per il packaging del gioco
RUN apt-get update && apt-get -y install autoconf && rm -rf /var/lib/apt/lists/*

WORKDIR /root