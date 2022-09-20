FROM openjdk:11
MAINTAINER Shivaji
COPY target/process-business-rules-springboot.jar process-business-rules-springboot.jar
ENTRYPOINT ["java","-jar","/process-business-rules-springboot.jar"]