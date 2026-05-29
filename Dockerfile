FROM swift:6.1-jammy as build
RUN apt-get update && apt-get install -y libsqlite3-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Package.swift Package.resolved ./
RUN swift package resolve 2>/dev/null || true
COPY Sources/ Sources/
COPY Resources/ Resources/
COPY Public/ Public/
RUN python3 -c "import re; t=open('Package.swift').read(); t=re.sub(r'\n\s*// Tests\n.*?(?=\n\s*\],)', '', t, flags=re.DOTALL); open('Package.swift','w').write(t)"
RUN swift build -c release -Xswiftc -cross-module-optimization \
    && mkdir -p /output \
    && find .build -name LOServer -type f -perm /111 -exec cp {} /output/LOServer \; \
    && find .build -name "*.resources" -type d -exec cp -r {} /output/ \; \
    && ls -la /output/

FROM swift:6.1-jammy-slim
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /output/ .
COPY --from=build /app/Resources ./Resources
COPY --from=build /app/Public ./Public
RUN chmod +x ./LOServer && ls -la ./LOServer && ./LOServer --version 2>&1 || echo "Binary exists but may not support --version"
ENV ENVIRONMENT=production
EXPOSE 8080
ENTRYPOINT ["./LOServer", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
