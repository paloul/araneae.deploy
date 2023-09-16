#!/bin/bash

namespacetodelete=${namespacedelete:-namespace}

while [ $# -gt 0 ]; do

   if [[ $1 == *"--"* ]]; then
        param="${1/--/}"
        declare $param="$2"
        echo $1 $2 # Optional to see the parameter:value result
   fi

  shift
done

# Need to run kubectl proxy in another terminal first
kubectl get ns ${namespacetodelete} -o json | jq '.spec.finalizers=[]' | curl -X PUT http://localhost:8001/api/v1/namespaces/${namespacetodelete}/finalize -H "Content-Type: application/json" --data @-
