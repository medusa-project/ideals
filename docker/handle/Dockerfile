FROM openjdk:11

# Install various dependencies
RUN apt-get -y install curl

ARG user=handle
ARG home=/home/$user
RUN adduser --home $home $user
WORKDIR $home

# Download & extract the handle server
RUN curl --silent -O https://www.handle.net/hnr-source/handle-9.2.0-distribution.tar.gz \
    && tar xfz handle-9.2.0-distribution.tar.gz \
    && rm handle-9.2.0-distribution.tar.gz

# Create the data directory
RUN mkdir -p /home/handle/handle-server
COPY docker/handle/handle-server /home/handle/handle-server

RUN chown -R $user:$user $home
USER $user

ENTRYPOINT /home/handle/handle-9.2.0/bin/hdl-server /home/handle/handle-server

# Sample request:
# curl -v -k --user 300%3A12345/ADMIN:password "https://127.0.0.1:8000/api/handles?prefix=12345"
