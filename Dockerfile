FROM hashicorp/terraform:0.13.3 as terraform

FROM  mcr.microsoft.com/azure-cli

RUN apk --update --no-cache add git openssh

WORKDIR /viya4-iac-azure

COPY --from=terraform /bin/terraform /bin/terraform

COPY . .

RUN terraform init /viya4-iac-azure

ENTRYPOINT ["/bin/terraform"]