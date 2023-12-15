FROM maven:3.8.5-eclipse-temurin-17 AS build
WORKDIR /app
COPY services/pricing .
COPY proto src/main/proto
RUN mvn package -DskipTests

##################################################################

FROM eclipse-temurin:17-jre-alpine@sha256:02c04793fa49ad5cd193c961403223755f9209a67894622e05438598b32f210e

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 50052

CMD ["java", "-jar", "app.jar"]