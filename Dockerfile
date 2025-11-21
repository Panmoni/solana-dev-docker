FROM ubuntu:25.10@sha256:af5be3d16518275dafdb50a567a594d0a8fd2a6cf053892307f1b604e44609f4

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
    chown -R solana:solana /home/solana && \
    echo '' >> /home/solana/.bashrc && \
    echo '# Add Solana CLI to PATH if installed' >> /home/solana/.bashrc && \
    echo 'if [ -d "$HOME/.local/share/solana/install/active_release/bin" ]; then' >> /home/solana/.bashrc && \
    echo '    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> /home/solana/.bashrc && \
    echo 'fi' >> /home/solana/.bashrc

WORKDIR /home/solana
USER solana

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["sleep", "infinity"]

