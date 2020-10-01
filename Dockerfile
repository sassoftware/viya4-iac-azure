FROM ubuntu:20.04 as baseline
WORKDIR /build
RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install python3 python3-dev python3-pip curl unzip
# Adjust python to use only Python 3
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
 && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

FROM baseline as tool_builder
ENV terraform_version=0.13.2
RUN curl -sLO https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip && unzip ./terraform_${terraform_version}_linux_amd64.zip \
  && curl -s https://sdk.cloud.google.com | bash

# Installation
FROM baseline

COPY --from=tool_builder /build/terraform /usr/local/bin/terraform
COPY --from=tool_builder /root/google-cloud-sdk /cloud/clis/google-cloud-sdk
COPY . /viya4-deployment

# Add extra packages
RUN apt-get -y install bash-completion git \
  && curl -sLO https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip && unzip awscli-exe-linux-x86_64.zip && ./aws/install && rm -rf awscli-exe-linux-x86_64.zip \
  && curl -so aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/aws-iam-authenticator && chmod 755 aws-iam-authenticator && mv aws-iam-authenticator /usr/local/bin/aws-iam-authenticator \
  && curl -sL https://aka.ms/InstallAzureCLIDeb | /bin/bash \  
  && echo 'source /cloud/clis/google-cloud-sdk/completion.bash.inc' >> ~/.bashrc \
  && echo 'source /cloud/clis/google-cloud-sdk/path.bash.inc' >> ~/.bashrc

WORKDIR /viya4-deployment

ENTRYPOINT ["/usr/local/bin/terraform"]