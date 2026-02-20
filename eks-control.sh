#!/bin/bash

CLUSTER="nginx-cluster"
NODEGROUP="nginx-nodes"
REGION="ap-south-1"

ACTION=$1
COUNT=$2

if [ "$ACTION" == "nodes" ]; then

  DESIRED=$(eksctl get nodegroup --cluster $CLUSTER --region $REGION --name $NODEGROUP -o json | jq -r '.[0].DesiredCapacity')
  STATUS=$(eksctl get nodegroup --cluster $CLUSTER --region $REGION --name $NODEGROUP -o json | jq -r '.[0].Status')

  READY=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
  NODES=$(kubectl get nodes --no-headers 2>/dev/null | awk '{print "- "$1"   "$2}')

  # If cluster is scaled down
  if [ "$DESIRED" -eq 0 ] && [ "$READY" -eq 0 ]; then

    echo "{\"text\":\"📊 EKS CLUSTER DASHBOARD\n\nCluster      : $CLUSTER\nNodegroup    : $NODEGROUP\nRegion       : $REGION\n\nDesired      : $DESIRED\nReady        : $READY\nStatus       : $STATUS\n\n⚠ Cluster is currently scaled down.\nNo worker nodes running.\"}"

  else

    echo "{\"text\":\"📊 EKS CLUSTER DASHBOARD\n\nCluster      : $CLUSTER\nNodegroup    : $NODEGROUP\nRegion       : $REGION\n\nDesired      : $DESIRED\nReady        : $READY\nStatus       : $STATUS\n\nNodes:\n$NODES\"}"

  fi

  exit 0
fi


if [ "$ACTION" == "setnode" ]; then

  if [ -z "$COUNT" ]; then
    echo "{\"text\":\"❌ Please provide node count. Example: set node 3\"}"
    exit 1
  fi

  CURRENT=$(eksctl get nodegroup --cluster $CLUSTER --region $REGION --name $NODEGROUP -o json | jq -r '.[0].DesiredCapacity')

  eksctl scale nodegroup \
    --cluster $CLUSTER \
    --name $NODEGROUP \
    --nodes $COUNT \
    --region $REGION > /dev/null 2>&1

  echo "{\"text\":\"🚀 Node Count Updated\n\nCluster   : $CLUSTER\nFrom      : $CURRENT nodes\nTo        : $COUNT nodes\n\nStatus    : Scaling in progress...\"}"

  exit 0
fi
