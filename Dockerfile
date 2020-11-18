ARG TERRAFORM_VERSION=0.13.4
ARG AZURECLI_VERSION=2.14.2

FROM hashicorp/terraform:$TERRAFORM_VERSION as terraform
FROM  mcr.microsoft.com/azure-cli:$AZURECLI_VERSION

COPY --from=terraform /bin/terraform /bin/terraform

WORKDIR /viya4-iac-azure

COPY . .

RUN apk --update --no-cache add git openssh \
  && terraform init /viya4-iac-azure

ENTRYPOINT ["/bin/terraform"]
