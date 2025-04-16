ARG TERRAFORM_VERSION=1.10.5
ARG AZURECLI_VERSION=2.70.0

FROM hashicorp/terraform:$TERRAFORM_VERSION AS terraform
FROM mcr.microsoft.com/azure-cli:$AZURECLI_VERSION
ARG KUBECTL_VERSION=1.30.10

WORKDIR /viya4-iac-azure

COPY --from=terraform /bin/terraform /bin/terraform
COPY . .

RUN tdnf -y install git which \
  && tdnf clean all && rm -rf /var/cache/tdnf \
  && curl -sLO https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl \
  && chmod 755 ./kubectl /viya4-iac-azure/docker-entrypoint.sh \
  && mv ./kubectl /usr/local/bin/kubectl \
  && git config --system --add safe.directory /viya4-iac-azure \
  && terraform init \
  && chmod g=u -R /etc/passwd /etc/group /viya4-iac-azure

ENV TF_VAR_iac_tooling=docker
ENTRYPOINT ["/viya4-iac-azure/docker-entrypoint.sh"]
VOLUME ["/workspace"]
