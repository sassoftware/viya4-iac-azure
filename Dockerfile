ARG TERRAFORM_VERSION=1.0.0
ARG AZURECLI_VERSION=2.24.2

FROM hashicorp/terraform:$TERRAFORM_VERSION as terraform
FROM mcr.microsoft.com/azure-cli:$AZURECLI_VERSION
ARG KUBECTL_VERSION=1.23.12

WORKDIR /viya4-iac-azure

COPY --from=terraform /bin/terraform /bin/terraform
COPY . .

RUN apk --update --no-cache add git openssh \
  && curl -sLO https://storage.googleapis.com/kubernetes-release/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl \
  && chmod 755 ./kubectl /viya4-iac-azure/docker-entrypoint.sh \
  && mv ./kubectl /usr/local/bin/kubectl \
  && chmod g=u -R /etc/passwd /etc/group /viya4-iac-azure \
  && git config --system --add safe.directory /viya4-iac-azure \
  && terraform init

ENV TF_VAR_iac_tooling=docker
ENTRYPOINT ["/viya4-iac-azure/docker-entrypoint.sh"]
VOLUME ["/workspace"]
