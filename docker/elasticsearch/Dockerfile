FROM elasticsearch:7.5.1

ENV discovery.type=single-node

RUN sed -i -e 's/rootLogger.level = info/rootLogger.level = error/g' config/log4j2.properties

RUN bin/elasticsearch-plugin install --batch analysis-icu