#!/bin/bash
helm upgrade --install test ./k8s/chart --namespace dev --values ./path/to/values  --verify