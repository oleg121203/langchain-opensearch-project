FROM opensearchproject/logstash-oss-with-opensearch-output-plugin:latest

USER root

# Install locales
RUN apt-get update && apt-get install -y locales && \
    localedef -i uk_UA -c -f UTF-8 -A /usr/share/locale/locale.alias uk_UA.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

# Set locale
ENV LANG uk_UA.UTF-8
ENV LANGUAGE uk_UA:uk
ENV LC_ALL uk_UA.UTF-8

# Create and set permissions for data directory
RUN mkdir -p /usr/share/logstash/data && \
    chown -R 1000:1000 /usr/share/logstash/data && \
    chmod 777 /usr/share/logstash/data

USER 1000:1000
