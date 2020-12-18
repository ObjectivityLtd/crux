#CREDIT: This is taken from https://github.com/markhobson/docker-maven-chrome/blob/master/jdk-8/Dockerfile
#Chrome as headless browser - v 87
FROM markhobson/maven-chrome@sha256:e5013aa2b127134e0f8f35e82528b6fc24d14b768a110e557fa53f07e202f755
#args
ARG JMETER_VERSION=5.4
ARG JMETER_INSTALLATION_DIR=/jmeter
ARG JMETER_DIR=$JMETER_INSTALLATION_DIR/apache-jmeter-$JMETER_VERSION
ARG CONTAINER_JMETER_TEST_DIR=/test
#setting /test dir as default jmeter dir amd copy test files for docker unit tests
RUN mkdir $CONTAINER_JMETER_TEST_DIR
#should replace .py test with .groovy test?
COPY test_data/*.py $CONTAINER_JMETER_TEST_DIR/
COPY test_data/*.jmx $CONTAINER_JMETER_TEST_DIR/
COPY test_data/*.csv $CONTAINER_JMETER_TEST_DIR/
WORKDIR $CONTAINER_JMETER_TEST_DIR

#replace python test with groovy?
#PIP, PIP LIBS for test,tools
RUN wget https://bootstrap.pypa.io/get-pip.py \
    && python get-pip.py \
    && pip install selenium \
	&& apt-get update -qqy \
	&& apt-get -qqy install vim groovy curl

RUN apt-get clean && \
    apt-get update && \
    apt-get -qy install \
    wget \
    telnet \
    screen \
    iputils-ping \
    unzip

#installing jmeter to /jmeter
RUN mkdir $JMETER_INSTALLATION_DIR \
    && cd $JMETER_INSTALLATION_DIR \
    && wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz \
    && tar -xzf apache-jmeter-$JMETER_VERSION.tgz \
    && rm apache-jmeter-$JMETER_VERSION.tgz

#plugins
ARG JMETER_PLUGINS_STANDARD_VERSION=1.4.0
RUN cd $JMETER_DIR/ && wget -q -O /tmp/JMeterPlugins-Standard.zip https://jmeter-plugins.org/downloads/file/JMeterPlugins-Standard-$JMETER_PLUGINS_STANDARD_VERSION.zip \
                     && unzip -n /tmp/JMeterPlugins-Standard.zip \
                     && rm /tmp/JMeterPlugins-Standard.zip

ARG JMETER_PLUGINS_BZM_PARALLEL_VERSION=0.8
RUN cd $JMETER_DIR/ && wget -q -O /tmp/bzm-parallel.zip https://jmeter-plugins.org/files/packages/bzm-parallel-$JMETER_PLUGINS_BZM_PARALLEL_VERSION.zip \
                    && unzip -n /tmp/bzm-parallel.zip \
                    && rm /tmp/bzm-parallel.zip

#3.3
ARG JMETER_PLUGINS_WEBDRIVER_VERSION=3.3
RUN cd $JMETER_DIR/ && wget -q -O /tmp/jpgc-webdriver.zip https://jmeter-plugins.org/files/packages/jpgc-webdriver-$JMETER_PLUGINS_WEBDRIVER_VERSION.zip \
                    && unzip -n /tmp/jpgc-webdriver.zip \
                    && rm /tmp/jpgc-webdriver.zip

ARG JMETER_PLUGINS_STS_VERSION=2.4
RUN cd $JMETER_DIR/ && wget -q -O /tmp/jpgc-sts.zip https://jmeter-plugins.org/files/packages/jpgc-sts-$JMETER_PLUGINS_STS_VERSION.zip \
                    && unzip -n /tmp/jpgc-sts.zip \
                     && rm /tmp/jpgc-sts.zip

ARG JMETER_PLUGINS_AZURE_BACKEND_LISTENER_VERSION=0.2.3
RUN wget -q -O $JMETER_DIR/lib/ext/jmeter.backendlistener.azure-$JMETER_PLUGINS_AZURE_BACKEND_LISTENER_VERSION.jar \
            https://github.com/adrianmo/jmeter-backend-azure/releases/download/$JMETER_PLUGINS_AZURE_BACKEND_LISTENER_VERSION/jmeter.backendlistener.azure-$JMETER_PLUGINS_AZURE_BACKEND_LISTENER_VERSION.jar

ENV JMETER_HOME $JMETER_DIR/
ENV PATH $JMETER_HOME/bin:$PATH
ENV JVM_ARGS -Xms1G -Xmx4G