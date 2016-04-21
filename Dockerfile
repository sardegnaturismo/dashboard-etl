FROM ubuntu:14.04

# Init ENV
ENV DEBIAN_FRONTEND noninteractive

ENV KETTLE_VERSION 5.0.1-stable
ENV KETTLE_TAG 5.0.1-stable

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

RUN mkdir -p ${PENTAHO_HOME}/.kettle
RUN mkdir -p ${PENTAHO_HOME}/setup
# Librerie customizzate
COPY ./kettle-engine-5.0.1-stable.jar ${PENTAHO_HOME}/data-integration/lib/kettle-engine-5.0.1-stable.jar
COPY ./kettle-ui-swt-5.0.1-stable-1.jar ${PENTAHO_HOME}/data-integration/lib/kettle-ui-swt-5.0.1-stable-1.jar
# Trasformazione kettle per cifratura password + script creazione file repositories.xml parametrizzato
COPY ./repositories_xml.ktr ${PENTAHO_HOME}/setup/repositories_xml.ktr
COPY ./create_repo.sh ${PENTAHO_HOME}/setup/create_repo.sh
# Script e trasformazione kettle per modifiche parametriche al file kettle.properties
COPY ./kettle.properties ${PENTAHO_HOME}/.kettle/kettle.properties
COPY ./kettle_properties.ktr ${PENTAHO_HOME}/setup/kettle_properties.ktr
COPY ./create_properties.sh ${PENTAHO_HOME}/setup/create_properties.sh
# Script trasformazioni kettle per caricamenti notturni
COPY scripts_trasformazioni ${PENTAHO_HOME}/setup/scripts_trasformazioni
# Script di orchestrazione all'avvio, richiama gli altri script
COPY ./setup.sh ${PENTAHO_HOME}/setup/setup.sh

USER root
RUN echo "pentaho ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN chown -R pentaho:pentaho ${PENTAHO_HOME}

USER pentaho

# Quando ci si collega alla bash, $pwd = WORKDIR
WORKDIR ${PENTAHO_HOME}

# Tramite la definizione del Volume, i file sotto ${PENTAHO_HOME} sono rimappati in maniera persistente sul FS dell'host
#VOLUME ${PENTAHO_HOME}

CMD ["/bin/bash", "/opt/pentaho/setup/setup.sh"]
