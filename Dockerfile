FROM --platform=$BUILDPLATFORM rust:1.84.0-alpine3.20 AS chef
# Install system dependencies and cargo-chef.
RUN apk add --no-cache alpine-sdk musl-dev g++ make libcrypto3 libressl-dev upx perl build-base
RUN cargo install cargo-chef --locked
WORKDIR /app

FROM chef AS planner
# Prepare dependency recipe.
COPY ./Cargo.toml ./Cargo.lock ./
RUN cargo chef prepare --recipe-path recipe.json

FROM --platform=$BUILDPLATFORM chef AS builder
# Copy recipe from planner.
COPY --from=planner /app/recipe.json recipe.json
# Cache type: memory, redis, hybrid, or no-cache.
ARG CACHE=memory
ENV CACHE=${CACHE}
# Get the target architecture from TARGETPLATFORM
ARG TARGETPLATFORM
RUN echo "TARGETPLATFORM: $TARGETPLATFORM"
RUN export TARGETARCH=$(echo $TARGETPLATFORM | cut -d / -f 2) && echo "TARGETARCH: $TARGETARCH"

# Cook dependencies.
RUN cargo chef cook --release --target=$TARGETARCH-unknown-linux-musl --recipe-path recipe.json $( [ "$CACHE" = "redis" ] || [ "$CACHE" = "hybrid" ] && echo "--features redis-cache" ) $( [ "$CACHE" != "redis" ] && [ "$CACHE" != "memory" ] && echo "--no-default-features")
# Copy source code.
COPY ./src ./src
COPY ./public ./public
# Build application.
RUN cargo build --release --target=$TARGETARCH-unknown-linux-musl $( [ "$CACHE" = "redis" ] || [ "$CACHE" = "hybrid" ] && echo "--features redis-cache" ) $( [ "$CACHE" != "redis" ] && [ "$CACHE" != "memory" ] && echo "--no-default-features")
# Optimise binary size.
RUN upx --lzma --best /app/target/$TARGETARCH-unknown-linux-musl/release/websurfx && \
    cp /app/target/$TARGETARCH-unknown-linux-musl/release/websurfx /usr/local/bin/websurfx

FROM --platform=$TARGETPLATFORM scratch
# Copy public directory.
COPY --from=builder /app/public/ /opt/websurfx/public/
# Configuration volume.
VOLUME ["/etc/xdg/websurfx/"]
# Copy optimized binary.
COPY --from=builder /usr/local/bin/websurfx /usr/local/bin/websurfx
# Run application.
CMD ["websurfx"]
