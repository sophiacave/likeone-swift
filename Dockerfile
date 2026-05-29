FROM swift:6.0-jammy as build
RUN apt-get update && apt-get install -y libsqlite3-dev && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Package.swift Package.resolved ./
RUN swift package resolve 2>/dev/null || true
COPY . .
RUN sed -i '/\.testTarget/d' Package.swift
RUN swift build -c release --target LOServer -Xswiftc -cross-module-optimization

FROM ubuntu:jammy
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/.build/release/LOServer .
COPY --from=build /app/Resources ./Resources
COPY --from=build /app/Public ./Public
COPY --from=build /app/.build/release/LOContent_LOContent.resources ./LOContent_LOContent.resources
ENV ENVIRONMENT=production
EXPOSE 8080
ENTRYPOINT ["./LOServer", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
