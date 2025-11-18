FROM docker.elastic.co/elasticsearch/elasticsearch:7.17.10

# Install the ingest-attachment plugin required by Zammad
RUN elasticsearch-plugin install --batch ingest-attachment
