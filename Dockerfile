###################### Build Stage ###################### 

# Gradle 8, Eclipse Temurin JDK 21, Ubuntu Jammy LTS Linux
FROM gradle:8-jdk21-jammy as builder

# run install tasks as root
USER root

# install Git
RUN \
	apt-get update \
	&& apt-get install --yes --no-install-recommends git \
	&& rm --recursive --force /var/lib/apt/lists/*

# run remainder of tasks as the unprivileged 'gradle' user
USER gradle

# clone repo
RUN git clone --quiet https://isgb.otago.ac.nz/infosci/git/INFO303/shopping.git

# switch into the repository directory
WORKDIR shopping

# checkout the release tag
RUN git checkout --quiet release

# add a volume for Gradle home
VOLUME "/home/gradle/.gradle"

# build the service
RUN gradle -Dorg.gradle.welcome=never --no-daemon --quiet installDist


###################### Run Stage ###################### 

# start with the much smaller JRE rather than JDK
FROM eclipse-temurin:21-jre-jammy

# copy the Gradle build output from the builder stage
COPY --from=builder /home/gradle/shopping/build/install /home/deployment

# switch into the stand-alone service folder
WORKDIR /home/deployment

# limit the Java heap size
ENV \
	_JAVA_OPTIONS=-Xmx256M

# the port that the service is using
EXPOSE 8080

# command to start the service
CMD shopping/bin/shopping
