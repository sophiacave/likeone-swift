FROM swift:6.0-jammy as build
RUN apt-get update && apt-get install -y libsqlite3-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Package.swift Package.resolved ./
RUN swift package resolve 2>/dev/null || true
COPY . .
RUN python3 -c "import re; t=open('Package.swift').read(); t=re.sub(r'\n\s*// Tests\n.*?(?=\n\s*\],)', '', t, flags=re.DOTALL); open('Package.swift','w').write(t)"
RUN swift build -c release -Xswiftc -cross-module-optimization && \
    BIN_PATH=$(swift build -c release --show-bin-path) && \
    echo "Binary path: $BIN_PATH" && \
    ls -la "$BIN_PATH"/LOServer* 2>/dev/null || echo "LOServer not at BIN_PATH" && \
    find .build -name "LOServer" -type f 2>/dev/null && \
    cp "$BIN_PATH/LOServer" /staging-binary && \
    mkdir -p /staging-resources && \
    find .build -name "LOContent_LOContent.resources" -type d -exec cp -r {} /staging-resources/ \;

FROM ubuntu:jammy
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /staging-binary ./LOServer
COPY --from=build /app/Resources ./Resources
COPY --from=build /app/Public ./Public
COPY --from=build /staging-resources/ .
ENV ENVIRONMENT=production
EXPOSE 8080
ENTRYPOINT ["./LOServer", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
