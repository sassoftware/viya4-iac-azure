FROM hashicorp/terraform:0.13.3

RUN apk --update --no-cache add libc6-compat git openssh-client py-pip bash \
  && apk add --virtual=build gcc libffi-dev musl-dev openssl-dev python3-dev make \
  && pip --no-cache-dir install -U pip \
  && pip install azure-cli \
  && apk del --purge build

WORKDIR /viya4-deployment

COPY . .

RUN terraform init /viya4-deployment