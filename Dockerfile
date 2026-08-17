FROM docker/sandbox-templates:shell-docker

USER root

# Pi requires Node; shell-docker already provides the sandbox base.
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

USER agent

ENTRYPOINT ["pi"]
