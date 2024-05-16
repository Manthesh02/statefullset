# Use an official Tomcat runtime as a base image
FROM tomcat:9-jre11-slim

# Copy the application WAR file into the webapps directory of Tomcat
COPY target/simplewebapp.war /usr/local/tomcat/webapps/

# Tomcat runs on port 8080 by default, so we expose that port       
EXPOSE 9001
