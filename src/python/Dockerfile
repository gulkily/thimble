from python:3.13-rc-alpine3.20

ARG PORT=8000
EXPOSE ${PORT}

WORKDIR /app

COPY src/python/requirements/prod.txt /tmp/requirements.txt

RUN apk update && \
    apk upgrade && \
    apk add \
      curl \
      gcc \
      git \
      python3-dev \
      musl-dev \
      linux-headers \
      vim && \
      pip install -r /tmp/requirements.txt && \
      git config --global --add safe.directory /app/message

CMD ["python", "start_server.py"]
