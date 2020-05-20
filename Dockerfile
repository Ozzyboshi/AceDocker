# Docker image for ACE Game engine

FROM ozzyboshi/bebbo-amiga-gcc:20200203 as build-env

## Start of ACE release

FROM ubuntu:18.04 as ace-env

COPY --from=build-env /opt/amiga ./opt/amiga

ARG ace_branch=master

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -y install git make g++ gcc cmake wget && rm -rf /var/lib/apt/lists/*

#ilbm2raw
WORKDIR /root
RUN wget 'https://github.com/Ozzyboshi/ilbm2raw/archive/v0.2.tar.gz'
RUN tar -xvzpf v0.2.tar.gz
RUN cd ilbm2raw-0.2/ && ./configure && make && make check && make install

WORKDIR /root

# fmt is needed to get ace tools running
RUN git clone https://github.com/fmtlib/fmt
RUN cd fmt && mkdir build && cd build && cmake .. && make && make install

WORKDIR /root
RUN git clone https://github.com/AmigaPorts/ACE.git && cd ACE && git checkout ${ace_branch}
RUN sed -i 's/INTF_PORTS | INTF_AUD0 | INTF_AUD1 | INTF_AUD2 | INTF_AUD3/INTF_PORTS/'  /root/ACE/src/ace/managers/system.c
RUN sed -i 's/s_pHwVectors[SYSTEM_INT_VECTOR_FIRST + i] = s_pAceHwInterrupts[i];/if (i<4) s_pHwVectors[SYSTEM_INT_VECTOR_FIRST + i] = s_pAceHwInterrupts[i];/' /root/ACE/src/ace/managers/system.c

RUN git clone https://github.com/AmigaPorts/AmigaCMakeCrossToolchains.git 

RUN cd ACE/tools && mkdir build
WORKDIR /root/ACE/tools/build
RUN  cmake .. && make

# fix utils path
WORKDIR /root
RUN mkdir ACE/tools/palette_conv && cp ACE/tools/bin/palette_conv /root/ACE/tools/palette_conv/palette_conv

WORKDIR /root
RUN cd ACE/ && mkdir build
WORKDIR /root/ACE/build
RUN M68K_TOOLCHAIN_PATH=/bin cmake .. -DCMAKE_TOOLCHAIN_FILE=/root/AmigaCMakeCrossToolchains/m68k-amigaos.cmake -DM68K_TOOLCHAIN_PATH=/opt/amiga -DTOOLCHAIN_PREFIX=m68k-amigaos  -DTOOLCHAIN_PREFIX_DASHED=m68k-amigaos- -DM68K_CPU=68000 -DM68K_FPU=soft
RUN make

WORKDIR /root
RUN cd ACE/showcase && mkdir build
WORKDIR /root/ACE/showcase/build
RUN M68K_TOOLCHAIN_PATH=/bin cmake .. -DCMAKE_TOOLCHAIN_FILE=/root/AmigaCMakeCrossToolchains/m68k-amigaos.cmake -DM68K_TOOLCHAIN_PATH=/opt/amiga -DTOOLCHAIN_PREFIX=m68k-amigaos -DTOOLCHAIN_PREFIX_DASHED=m68k-amigaos- -DM68K_CPU=68000 -DM68K_FPU=soft
RUN make
## End of ace regular


## Start of ACE debug

FROM ubuntu:18.04 as acedebug-env

COPY --from=build-env /opt/amiga ./opt/amiga

ARG ace_branch=master

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -y install git make g++ gcc cmake && rm -rf /var/lib/apt/lists/*

WORKDIR /root

WORKDIR /root
RUN git clone https://github.com/AmigaPorts/ACE.git && cd ACE && git checkout ${ace_branch}
RUN sed -i 's/INTF_PORTS | INTF_AUD0 | INTF_AUD1 | INTF_AUD2 | INTF_AUD3/INTF_PORTS/'  /root/ACE/src/ace/managers/system.c
RUN sed -i 's/s_pHwVectors[SYSTEM_INT_VECTOR_FIRST + i] = s_pAceHwInterrupts[i];/if (i<4) s_pHwVectors[SYSTEM_INT_VECTOR_FIRST + i] = s_pAceHwInterrupts[i];/' /root/ACE/src/ace/managers/system.c

RUN git clone https://github.com/AmigaPorts/AmigaCMakeCrossToolchains.git 

WORKDIR /root
RUN cd ACE/ && mkdir build
WORKDIR /root/ACE/build
RUN M68K_TOOLCHAIN_PATH=/bin cmake .. -DCMAKE_TOOLCHAIN_FILE=/root/AmigaCMakeCrossToolchains/m68k-amigaos.cmake -DM68K_TOOLCHAIN_PATH=/opt/amiga -DTOOLCHAIN_PREFIX=m68k-amigaos  -DTOOLCHAIN_PREFIX_DASHED=m68k-amigaos- -DM68K_TOOLCHAIN_PATH=/opt/amiga -DM68K_CPU=68000 -DM68K_FPU=soft -DCMAKE_BUILD_TYPE=Debug -DACE_DEBUG=1
RUN make
## End of ace debug

## Start of ACE release
FROM ubuntu:18.04 as acerelease-env

COPY --from=build-env /opt/amiga ./opt/amiga

ARG ace_branch=master

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get -y install git make g++ gcc cmake && rm -rf /var/lib/apt/lists/*

WORKDIR /root
RUN git clone https://github.com/AmigaPorts/ACE.git && cd ACE && git checkout ${ace_branch}
RUN sed -i 's/INTF_PORTS | INTF_AUD0 | INTF_AUD1 | INTF_AUD2 | INTF_AUD3/INTF_PORTS/'  /root/ACE/src/ace/managers/system.c
RUN sed -i 's/s_pHwVectors[SYSTEM_INT_VECTOR_FIRST + i] = s_pAceHwInterrupts[i];/if (i<4) s_pHwVectors[SYSTEM_INT_VECTOR_FIRST + i] = s_pAceHwInterrupts[i];/' /root/ACE/src/ace/managers/system.c

RUN git clone https://github.com/AmigaPorts/AmigaCMakeCrossToolchains.git 

WORKDIR /root
RUN cd ACE/ && mkdir build
WORKDIR /root/ACE/build
RUN M68K_TOOLCHAIN_PATH=/bin cmake .. -DCMAKE_TOOLCHAIN_FILE=/root/AmigaCMakeCrossToolchains/m68k-amigaos.cmake -DM68K_TOOLCHAIN_PATH=/opt/amiga -DM68K_TOOLCHAIN_PATH=/opt/amiga -DTOOLCHAIN_PREFIX=m68k-amigaos  -DTOOLCHAIN_PREFIX_DASHED=m68k-amigaos- -DM68K_TOOLCHAIN_PATH=/opt/amiga -DM68K_CPU=68000 -DM68K_FPU=soft -DCMAKE_BUILD_TYPE=Release
RUN make

## End of ace release

FROM ubuntu:18.04

MAINTAINER Ozzyboshi <gun101@email.it>

# game packaging only
RUN apt-get update && apt-get -y install libmpc3 make autoconf && rm -rf /var/lib/apt/lists/*

COPY --from=build-env /opt/amiga ./opt/amiga
COPY --from=ace-env /root/ACE/build/libace.a /opt/amiga/lib/
COPY --from=ace-env /root/ACE/showcase /opt/amiga/showcase
COPY --from=acedebug-env /root/ACE/build/libace.a /opt/amiga/lib/libacedebug.a
COPY --from=acerelease-env /root/ACE/build/libace.a /opt/amiga/lib/libacerelease.a
COPY --from=ace-env /root/ACE/tools/bin/* /usr/local/bin/
COPY --from=ace-env /root/ACE/include/ace /opt/amiga/include/ace
COPY --from=ace-env /root/ACE/include/fixmath /opt/amiga/include/fixmath
COPY --from=ace-env /usr/local/bin/ilbm2raw /usr/local/bin/ilbm2raw

# Copy incbin and incbin_fast
COPY incbin.sh /usr/local/bin/
COPY incbin_fast.sh /usr/local/bin/

# COPY ACE MAKE TOOL FOR FAST BOOTSTRAP NEW PROJECTS
COPY ace_make_tool.sh /usr/local/bin/

# Copy exe2adf
COPY exe2adf-linux64bit /usr/local/bin/

#Update Path for amiga executables
ENV PATH="/opt/amiga/bin:${PATH}"

WORKDIR /root
