FROM alpine:latest

RUN apk add jq curl bash

COPY update_dns.sh /

CMD [ "/bin/bash", "/update_dns.sh" ]