# ---- Build stage ----
FROM eclipse-temurin:25-jdk-noble AS builder
WORKDIR /app

# Copy Gradle wrapper and dependency manifests first (better layer caching)
COPY gradlew .
COPY gradle/ gradle/
COPY build.gradle .
COPY settings.gradle .

# Pre-fetch dependencies
RUN ./gradlew dependencies --no-daemon -q 2>/dev/null || true

# Copy source and build
COPY src/ src/
RUN ./gradlew bootJar --no-daemon -x test

# ---- Extract layers (Spring Boot layertools) ----
FROM eclipse-temurin:25-jdk-noble AS layers
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
RUN java -Djarmode=tools -jar app.jar extract --layers --launcher

# ---- Runtime stage (distroless) ----
FROM gcr.io/distroless/java25-debian13
WORKDIR /app

ENV APP_PORT=8081
ENV APP_HOST=0.0.0.0

# Copy Spring Boot layers in order (less-volatile first for caching)
COPY --from=layers /app/dependencies/          ./
COPY --from=layers /app/spring-boot-loader/    ./
COPY --from=layers /app/snapshot-dependencies/ ./
COPY --from=layers /app/application/           ./

EXPOSE 8081

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]

