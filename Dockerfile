FROM hashicorp/terraform:0.13.3

WORKDIR /viya4-iac-azure
COPY ./ /viya4-iac-azure/

RUN terraform init
