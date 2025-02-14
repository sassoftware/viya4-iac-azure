FROM golang:1.23

# todo download keyring from hashicorp and use it to verify
# --mount=type=bind,source=hashicorp-gpg-keyring,target=/tmp/hashicorp-gpg-keyring
RUN \
    apt-get update \
    && apt-get install -y jq lsb-release \
    && wget -O - https://apt.releases.hashicorp.com/gpg \
        | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt update \
    && apt install terraform \
    && ssh-keygen -f ~/.ssh/id_rsa -P ""