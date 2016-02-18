FROM ubuntu:14.04

# Init ENV
ENV DEBIAN_FRONTEND noninteractive

ENV KETTLE_VERSION 5.4
ENV KETTLE_TAG 5.4.0.1-130

ENV PENTAHO_HOME /opt/pentaho

#Install Updates, Dependencies and Oracle JDK 7
RUN apt-get update; apt-get install zip netcat -y; \
    apt-get install wget unzip vim python-software-properties software-properties-common -y; \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    add-apt-repository -y ppa:webupd8team/java && \
    apt-get update && \
    apt-get install -y oracle-java7-installer && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -rf /var/cache/oracle-jdk7-installer

# Apply JAVA_HOME
ENV PENTAHO_JAVA_HOME $JAVA_HOME
ENV PENTAHO_JAVA_HOME /usr/lib/jvm/java-7-oracle
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

RUN mkdir ${PENTAHO_HOME}; useradd -s /bin/bash -d ${PENTAHO_HOME} pentaho; chown pentaho:pentaho ${PENTAHO_HOME}

USER pentaho

# Download Pentaho Data Integration
RUN /usr/bin/wget --progress=dot:giga http://downloads.sourceforge.net/project/pentaho/Data%20Integration/${KETTLE_VERSION}/pdi-ce-${KETTLE_TAG}.zip -O /tmp/pdi-ce-${KETTLE_TAG}.zip; \
    /usr/bin/unzip -q /tmp/pdi-ce-${KETTLE_TAG}.zip -d  $PENTAHO_HOME; \
    rm /tmp/pdi-ce-${KETTLE_TAG}.zip

# Quando ci si collega alla bash, $pwd = WORKDIR
WORKDIR /opt/pentaho

# Tramite la definizione del Volume, i file sotto /opt/pentaho sono rimappati in maniera persistente sul FS dell'host
VOLUME /opt/pentaho
