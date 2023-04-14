#!/bin/bash
DISTRIBUTION_PATH="./distribution"

githttpsusername=${githttpsusername:-admin} # The Git repo's https username as default admin
githttpspassword=${githttpspassword:-password} # The Git repo's https password as default admin

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        echo $1 $2 # Optional to see the parameter:value result
   fi

  shift
done

kubectl create secret generic -n argocd git-repo-secret --from-literal=HTTPS_USERNAME=${git-https-username} --from-literal=HTTPS_PASSWORD=${git-https-password} --dry-run=client -o yaml | kubeseal | yq eval -P > ${DISTRIBUTION_PATH}/argocd/overlays/private-repo/secret.yaml