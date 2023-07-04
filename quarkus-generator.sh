#!/bin/bash

# Check if the required arguments are provided
if [ $# -lt 2 ]; then
  echo "Usage: $0 <groupId> <artifactId>"
  exit 1
fi

GROUPID=$1
ARTIFACTID=$2

# Convert artifactId to PascalCase for className
CLASSNAME=$(echo "$ARTIFACTID" | sed 's/-\([a-z]\)/\U\1/g; s/^\([a-z]\)/\U\1/g; s/-//g; s/_//g')

# Determine the latest version of Quarkus
LATEST_VERSION=$(curl -s "https://api.github.com/repos/quarkusio/quarkus/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

# Create a new Quarkus project with the specified extensions
mvn io.quarkus:quarkus-maven-plugin:$LATEST_VERSION:create \
    -DprojectGroupId=$GROUPID \
    -DprojectArtifactId=$ARTIFACTID \
    -DclassName="$GROUPID.$CLASSNAME" \
    -Dpath="/$ARTIFACTID" \
    -Dextensions="resteasy-reactive,resteasy-reactive-jackson,jdbc-h2,hibernate-orm-panache,hibernate-validator,flyway,smallrye-openapi"

# Change into the newly created project directory
cd $ARTIFACTID


sed -i '/<\/dependencies>/i \
    <dependency> \
        <groupId>org.projectlombok</groupId> \
        <artifactId>lombok</artifactId> \
        <version>1.18.28</version> \
        <scope>provided</scope> \
    </dependency>' pom.xml

# Add the required properties to application.properties
echo "quarkus.package.type=uber-jar
quarkus.live-reload.instrumentation=true
%dev.quarkus.hibernate-orm.database.generation=drop-and-create
quarkus.datasource.db-kind=h2
quarkus.datasource.username=username-default
quarkus.datasource.jdbc.url=jdbc:h2:~/$ARTIFACTID-h2
quarkus.datasource.jdbc.max-size=13" >> src/main/resources/application.properties

echo "Quarkus project created successfully!"
