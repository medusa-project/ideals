# The parent Dockerfile has a lot of layers which may lead to "max depth
# exceeded" messages. This version is known to work.
FROM rabbitmq:3.8.5

ENV RABBITMQ_DEFAULT_USER=ideals
ENV RABBITMQ_DEFAULT_PASS=password

ADD docker/rabbitmq/rabbitmq.conf /etc/rabbitmq/
ADD docker/rabbitmq/definitions.json /etc/rabbitmq/

RUN chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.conf /etc/rabbitmq/definitions.json

RUN rabbitmq-plugins enable rabbitmq_management