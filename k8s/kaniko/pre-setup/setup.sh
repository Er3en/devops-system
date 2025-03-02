#!/bin/bash
kubectl create namespace kaniko
kubectl config set-context --current --namespace kaniko

user="user"
token="token"
namespace='kaniko'

auth=$(echo -n "${user}:${token}" | base64)

# Create the config.json file
cat <<EOF > config.json
{
  "auths": {
    "https://ghcr.io": {
      "auth": "${auth}"
    }
  }
}
EOF

# Create the Kubernetes secret
kubectl create secret generic ghcr-token --from-file=./config.json --namespace=$namespace

# Clean up the config.json file
rm config.json
