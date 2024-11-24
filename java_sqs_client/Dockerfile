#Build project
FROM maven:3.9.4-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn package

# Use a lightweight base image for running the application
FROM eclipse-temurin:17-jdk-alpine

# Copy the JAR file
COPY --from=builder /app/target/imagegenerator-0.0.1-SNAPSHOT.jar app.jar

# Expose the default Spring Boot port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]