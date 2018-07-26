FROM rust:1.27.2-jessie as builder

ENV RUST_BACKTRACE=1

# RUN sed -i -e 's%http://archive.ubuntu.com/ubuntu%mirror://mirrors.ubuntu.com/mirrors.txt%' -e 's/^deb-src/#deb-src/' /etc/apt/sources.list
RUN apt-get update && \
    apt-get install curl\
        musl-dev musl-tools \
        build-essential \
        ocl-icd-opencl-dev -y\
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# RUN ~/.cargo/bin/rustup target add ${TARGET}

COPY . /src
WORKDIR /src

RUN cargo build --release

FROM debian:jessie
RUN apt-get update && \
    apt-get install ocl-icd-opencl-dev -y\
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV CPU_THREADS=50

COPY --from=builder /src/target/release/nano-work-server /usr/local/bin/

RUN chmod +x /usr/local/bin/nano-work-server

EXPOSE 7076

CMD ["sh","-c", "nano-work-server -c ${CPU_THREADS} -l [::ffff:0.0.0.0]:7076"]
