#!/bin/bash
echo $DO_PAT
terraform validate
terraform plan -var "do_token=$DO_PAT" -out tfplanexit
terraform apply -var "do_token=$DO_PAT" -auto-approve