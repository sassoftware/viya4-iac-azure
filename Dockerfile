FROM ubuntu:20.04 as baseline
# Update baseline OS.
WORKDIR /build
RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install python3 python3-dev python3-pip curl unzip
# Adjust python to use only Python 3
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
 && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Install Terraform
FROM baseline as terraform_builder
ENV version=0.13.2
RUN curl -sLO https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip && unzip ./terraform_${version}_linux_amd64.zip

# Installation
FROM baseline
# Add extra packages
RUN apt-get -y install apt-utils tree vim nano
# Install tooling
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash 
# Copy items from 'build' images above
COPY --from=terraform_builder /build/terraform /usr/local/bin/terraform

# Entry point
WORKDIR /root
ENTRYPOINT ["/usr/bin/bash","-l"]