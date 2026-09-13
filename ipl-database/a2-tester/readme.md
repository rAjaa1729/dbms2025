# Instructions

## How to setup

1. Install Apache Maven version 3.9.9 in your local machine.

2. Install jdk-8.

Ensure that `mvn -version` and `java -version` give dersired outputs in terminal. You might need to set `$JAVA_HOME` variable in Windows and similarly for Linux and Mac.

## How to run

Paste your solution in `src/test/resources/schema.sql`, add password to your "postgres" in `src/main/java/com/example/DatabaseConnection.java` and run the below to command to run the testcases:

    mvn test -DtrimStackTrace=true

To enable error stacktrace, just run

    mvn test
