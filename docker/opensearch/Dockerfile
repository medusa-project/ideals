FROM public.ecr.aws/opensearchproject/opensearch:1

ENV discovery.type=single-node

RUN sed -i -e 's/rootLogger.level = info/rootLogger.level = error/g' config/log4j2.properties \
    && echo "plugins.security.disabled: true" >> config/opensearch.yml \
    && echo "plugins.index_state_management.enabled: false" >> config/opensearch.yml

RUN bin/opensearch-plugin install --batch analysis-icu