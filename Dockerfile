FROM ubuntu:25.04@sha256:34e8533bf27ac50f60bec267f6ce18c9aeb9556574e1ec1a8ce89926d32ea8f3

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      build-essential \
      pkg-config \
      libssl-dev \
      sudo \
      tini && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash solana && \
    echo 'solana ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    chown -R solana:solana /home/solana

WORKDIR /home/solana
USER solana

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sleep", "infinity"]

