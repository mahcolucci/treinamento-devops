FROM openjdk:8-jdk-alpine
VOLUME /tmp
COPY target/SpringWeb-1.0.0.jar app.jar
ENV JAVA_OPTS=""
ENTRYPOINT exec java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=9999 -jar /app.jar