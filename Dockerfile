FROM swift:6.0-jammy as build
WORKDIR /app
COPY Package.swift ./
RUN swift package resolve 2>/dev/null || true
COPY . .
RUN swift build -c release

FROM ubuntu:jammy
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/.build/release/LikeOneSwift .
COPY --from=build /app/Resources ./Resources
COPY --from=build /app/Public ./Public
ENV ENVIRONMENT=production
EXPOSE 8080
ENTRYPOINT ["./LikeOneSwift", "serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
