FROM ubuntu:16.04 as builder

ENV TARGET=x86_64-unknown-linux-musl
ENV BUILD_DIR=/src/target/x86_64-unknown-linux-musl/release/
ENV RUST_BACKTRACE=1

# RUN sed -i -e 's%http://archive.ubuntu.com/ubuntu%mirror://mirrors.ubuntu.com/mirrors.txt%' -e 's/^deb-src/#deb-src/' /etc/apt/sources.list
RUN apt-get update && \
    apt-get install curl\
        musl-dev musl-tools \
        build-essential \
        ocl-icd-opencl-dev -y\
    && apt-get clean && rm -rf /var/lib/apt/lists/*
    
RUN curl https://sh.rustup.rs -sSf -o /tmp/rustup-init.sh
RUN sh /tmp/rustup-init.sh -y

RUN ~/.cargo/bin/rustup target add ${TARGET}

COPY . /src
WORKDIR /src

# RUN ~/.cargo/bin/cargo test --release --target=${TARGET}
RUN ~/.cargo/bin/cargo build --release --target=${TARGET}

# Build artifacts will be available in /app.
RUN mkdir /app
# # Copy the "interesting" files into /app.
RUN find ${BUILD_DIR} \
                -regextype egrep \
                # The interesting binaries are all directly in ${BUILD_DIR}.
                -maxdepth 1 \
                # Well, binaries are executable.
                -executable \
                # Well, binaries are files.hello2
                -type f \
                # Filter out tests.
                ! -regex ".*\-[a-fA-F0-9]{16,16}$" \
                # Copy the matching files into /app.
                -exec cp {} /app \;

RUN echo "The following files will be copied to the runtime image: $(ls -al /app); $(ls -al /src/target/x86_64-unknown-linux-musl/release/)"

FROM ubuntu:16.04
RUN apt-get update && \
    apt-get install ocl-icd-opencl-dev -y\
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV CPU_THREADS=1000

COPY --from=builder /src/target/x86_64-unknown-linux-musl/release/nano-work-server /usr/local/bin/
RUN chmod +x /usr/local/bin/nano-work-server

EXPOSE 7076
CMD ["nano-work-server", "-c", "${CPU_THREADS}"]
