#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
#!/bin/bash


echo "Starting Provisionning Machines on the Cloud"

# Mandatory settings
export CLUSTER_NAME=
export CLOUD_PROVIDER="AWS" 
export CLUSTER_TYPE="basic"
export PUBLIC_KEY_PATH=~/.ssh/id_rsa.pub
export PRIVATE_KEY_PATH="~/.ssh/id_rsa"
export INITIAL_NODE_USER="rocky"
export WHITELIST_IPS=""
# Use for tagging resources on 
export RESOURCE_OWNER=$(whoami)

# Related to AWS
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export KEY_PAIR_NAME=""
export AMI_ID="ami-0618721d17eff62b0"
export REGION="eu-west-3"

# To get info on deployments to make (nodes, sizes)
export FREE_IPA="false"
export ENCRYPTION_ACTIVATED="false"
export MASTER_COUNT=0
export WORKER_COUNT=0
export WORKER_STREAM_COUNT=0
export ECS_MASTER_COUNT=0
export ECS_WORKER_COUNT=0
export MASTER_TYPE="t2.2xlarge"
export WORKER_TYPE="t2.2xlarge"
export WORKER_STREAM_TYPE="t2.2xlarge"
export IPA_TYPE="t2.small"
export KTS_TYPE="t2.small"
export ECS_MASTER_TYPE="t2.2xlarge"
export ECS_WORKER_TYPE="m5a.8xlarge"
export MASTER_DISK_SIZE="128"
export WORKER_DISK_SIZE="512"
export WORKER_STREAM_DISK_SIZE="128"
export IPA_DISK_SIZE="64"
export KTS_DISK_SIZE="64"
export ECS_MASTER_DISK_SIZE="128"
export ECS_WORKER_DISK_SIZE="256"
export OS="rhel"
export OS_VERSION="8.8"
# TODO: Add configuration of Domain Name
export DOMAIN_NAME=""

# For Debugging
export DEBUG="false"
export APPLY_CLOUD_MACHINES_PREREQUISITES="true"
export TF_BASE_WORK_DIR="/tmp"
export IS_PVC=false


function usage()
{
    echo "This script aims to provision machines on cloud and then launch installation of a cluster"
    echo ""
    echo "Usage is the following : "
    echo ""
    echo "./setup-cluster-on-cloud.sh"
    echo "  -h --help"
    echo "  --cluster-name=$CLUSTER_NAME Required as it will be the name of the cluster in cloudcat (Default) "
    echo "  --cloud-provider=$CLOUD_PROVIDER : The cloud provider to use among AWS, (GCP, AZURE not supported) (Default) AWS"
    echo "  --cluster-type=$CLUSTER_TYPE : Choices: basic, basic-enc, streaming, pvc, pvc-oc, full, full-enc-pvc, observability, cdh5, cdh6, hdp3, hdp2 (Default) $ Will install a CDP 7 with almost all services"
    echo "  --public-key-path=$PUBLIC_KEY_PATH : The path to your public key, used to setup password-less connections to nodes (Default) ${PUBLIC_KEY_PATH}"
    echo "  --private-key-path=$PRIVATE_KEY_PATH : Mandatory to get access to machines"
    echo "  --initial-node-user=$INITIAL_NODE_USER : Mandatory to get access to machines"
    echo "  --resource-owner=$RESOURCE_OWNER : Use to tag resources on Cloud Provider (Default) $RESOURCE_OWNER"
    echo ""
    echo " Parameters only required for AWS : "
    echo "  --aws-access-key=$AWS_ACCESS_KEY_ID : Mandatory to get access to AWS account"
    echo "  --aws-secret-access-key=$AWS_SECRET_ACCESS_KEY : Mandatory to get access to AWS account"
    echo "  --aws-key-pair-name=$KEY_PAIR_NAME : Mandatory to get access to AWS account"
    echo "  --aws-private-key-path=$PRIVATE_KEY_PATH : Mandatory to get access to AWS account"
    echo "  --whitelist-ips=$WHITELIST_IPS : IP to whitelist for all incoming connections to instances"
    echo "  --ami-id=$AMI_ID : (Optional) The cloud provider to use among YCLOUD, GCE, AWS (Default) "
    echo "  --region=$REGION : (Optional) Name of the region, provider-dependent where to provisioon machines (Default) eu-west-3"
    echo ""
    echo "Parameters to set numer of nodes and size"
    echo "  --free-ipa=$FREE_IPA : (Optional) To install Free IPA and use it or not (Default) $FREE_IPA "
    echo "  --encryption-activated=$ENCRYPTION_ACTIVATED : (Optional) To setup TDE with KTS/KMS (only on CDP) (Default) $ENCRYPTION_ACTIVATED  "
    echo "  --master-count=$MASTER_COUNT : (Optional)   (Default) $MASTER_COUNT"
    echo "  --worker-count=$WORKER_COUNT : (Optional)   (Default) $WORKER_COUNT"
    echo "  --worker-stream-count=$WORKER_STREAM_COUNT : (Optional)   (Default) $WORKER_STREAM_COUNT"
    echo "  --ecs-master-count=$ECS_MASTER_COUNT : (Optional)   (Default) $ECS_MASTER_COUNT"
    echo "  --ecs-worker-count=$ECS_WORKER_COUNT : (Optional)   (Default) $ECS_WORKER_COUNT"
    echo "  --master-type=$MASTER_TYPE : (Optional)   (Default) $MASTER_TYPE"
    echo "  --worker-type=$WORKER_TYPE : (Optional)   (Default) $WORKER_TYPE"
    echo "  --worker-stream-type=$WORKER_STREAM_TYPE : (Optional)   (Default) $WORKER_STREAM_TYPE"
    echo "  --ipa-type=$IPA_TYPE : (Optional)   (Default) $IPA_TYPE"
    echo "  --kts-type=$KTS_TYPE : (Optional)   (Default) $KTS_TYPE"
    echo "  --ecs-master-type=$ECS_MASTER_TYPE : (Optional)   (Default) $ECS_MASTER_TYPE"
    echo "  --ecs-worker-type=$ECS_WORKER_TYPE : (Optional)   (Default) $ECS_WORKER_TYPE"
    echo "  --master-disk-size=$MASTER_DISK_SIZE : (Optional)   (Default) $MASTER_DISK_SIZE"
    echo "  --worker-disk-size=$WORKER_DISK_SIZE : (Optional)   (Default) $WORKER_DISK_SIZE"
    echo "  --worker-stream-disk-size=$WORKER_STREAM_DISK_SIZE : (Optional)   (Default) $WORKER_STREAM_DISK_SIZE"
    echo "  --ipa-disk-size=$IPA_DISK_SIZE : (Optional)   (Default) $IPA_DISK_SIZE"
    echo "  --kts-disk-size=$KTS_DISK_SIZE : (Optional)   (Default) $KTS_DISK_SIZE"
    echo "  --ecs-master-disk-size=$ECS_MASTER_DISK_SIZE : (Optional)   (Default) $ECS_MASTER_DISK_SIZE"
    echo "  --ecs-worker-disk-size=$ECS_WORKER_DISK_SIZE : (Optional)   (Default) $ECS_WORKER_DISK_SIZE"
    echo "  --os=$OS : (Optional) OS to use (Default) $OS"
    echo "  --os-version=$OS_VERSION : (Optional) OS version to use (Default) $OS_VERSION" 
    echo ""
    echo "  --debug=$DEBUG : (Optional) To activate debug "
    echo "  --apply-cloud-machine-prereqs=$APPLY_CLOUD_MACHINES_PREREQUISITES : (Optional) To apply or not cloud machiens prerequisites specific to each cloud provider (Default) $APPLY_CLOUD_MACHINES_PREREQUISITES"
    echo "  --tf-base-work-dir=$TF_BASE_WORK_DIR : (Optional) To change the default base working directory of terraform (Default) ${TF_BASE_WORK_DIR} "
    echo ""
    echo " <ALL_OTHER_PARAMETERS_TO_SETUP_CLUSTER_SCRIPT> : Add all other Parameters "
    echo ""
}

export ALL_PARAMETERS=$(echo $@)


while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --cluster-name)
            CLUSTER_NAME=$VALUE
            ;;    
        --cloud-provider)
            CLOUD_PROVIDER=$VALUE
            ;;
        --cluster-type)
            CLUSTER_TYPE=$VALUE
            ;;
        --public-key-path)
            PUBLIC_KEY_PATH=$VALUE
            ;;
        --private-key-path)
            PRIVATE_KEY_PATH=$VALUE
            ;;
        --initial-node-user)
            INITIAL_NODE_USER=$VALUE
            ;;
        --resource-owner)
            RESOURCE_OWNER=$VALUE
            ;;
        --debug)
            DEBUG=$VALUE
            ;;
        --apply-cloud-machine-prereqs)
            APPLY_CLOUD_MACHINES_PREREQUISITES=$VALUE
            ;;
        --free-ipa)
            FREE_IPA=$VALUE
            ;;
        --encryption-activated)
            ENCRYPTION_ACTIVATED=$VALUE
            ;;
        --aws-access-key)
            AWS_ACCESS_KEY_ID=$VALUE
            ;;
        --aws-secret-access-key)
            AWS_SECRET_ACCESS_KEY=$VALUE
            ;;
        --aws-key-pair-name)
            KEY_PAIR_NAME=$VALUE
            ;;
        --whitelist-ips)
            WHITELIST_IPS=$VALUE
            ;;
        --ami-id)
            AMI_ID=$VALUE
            ;;
        --region)
            REGION=$VALUE
            ;; 
        --master-count)
            MASTER_COUNT=$VALUE
            ;;
        --worker-count)
            WORKER_COUNT=$VALUE
            ;;
         --worker-stream-count)
            WORKER_STREAM_COUNT=$VALUE
            ;;
        --ecs-master-count)
            ECS_MASTER_COUNT=$VALUE
            ;;
        --ecs-worker-count)
            ECS_WORKER_COUNT=$VALUE
            ;;
        --master-type)
            MASTER_TYPE=$VALUE
            ;;
        --worker-type)
            WORKER_TYPE=$VALUE
            ;;
        --worker-stream-type)
            WORKER_STREAM_TYPE=$VALUE
            ;;
        --ipa-type)
            IPA_TYPE=$VALUE
            ;;
        --kts-type)
            KTS_TYPE=$VALUE
            ;;
        --ecs-master-type)
            ECS_MASTER_TYPE=$VALUE
            ;;
        --ecs-worker-type)
            ECS_WORKER_TYPE=$VALUE
            ;;
        --master-disk-size)
            MASTER_DISK_SIZE=$VALUE
            ;;
        --worker-disk-size)
            WORKER_DISK_SIZE=$VALUE
            ;;
         --worker-stream-disk-size)
            WORKER_STREAM_DISK_SIZE=$VALUE
            ;;
        --ipa-disk-size)
            IPA_DISK_SIZE=$VALUE
            ;;
        --kts-disk-size)
            KTS_DISK_SIZE=$VALUE
            ;;
        --ecs-master-disk-size)
            ECS_MASTER_DISK_SIZE=$VALUE
            ;;
        --ecs-worker-disk-size)
            ECS_WORKER_DISK_SIZE=$VALUE
            ;;
        --os)
            OS=$VALUE
            ;;
        --os-version)
            OS_VERSION=$VALUE
            ;; 
        --tf-base-work-dir)
            TF_BASE_WORK_DIR=$VALUE
            ;;        
        *)
            ;;
    esac
    shift
done

# Load logger
. ./logger.sh

# Setup Variables for execution of terraform

export TF_FILE_TEMPLATE_NAME=""
if [ "${CLOUD_PROVIDER}" = "AWS" ]
then
    export TF_FILE_TEMPLATE_NAME="aws"
elif [ "${CLOUD_PROVIDER}" = "GCP" ]
then
    export TF_FILE_TEMPLATE_NAME="gcp"
elif [ "${CLOUD_PROVIDER}" = "AZURE" ]
then
    export TF_FILE_TEMPLATE_NAME="azure"
fi

if [ ! -z ${CLUSTER_TYPE} ]
then
    if [ "${CLUSTER_TYPE}" = "basic" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=3
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
    elif [ "${CLUSTER_TYPE}" = "basic-enc" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=3
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
        export ENCRYPTION_ACTIVATED="true"
    elif [ "${CLUSTER_TYPE}" = "full" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=4
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
        if [ "${WORKER_STREAM_COUNT}" = 0 ]
        then
            export WORKER_STREAM_COUNT=3
        fi
    elif [ "${CLUSTER_TYPE}" = "all-services" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=4
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
        if [ "${WORKER_STREAM_COUNT}" = 0 ]
        then
            export WORKER_STREAM_COUNT=3
        fi
        export ENCRYPTION_ACTIVATED="true"
    elif [ "${CLUSTER_TYPE}" = "all-services-pvc" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=4
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
        if [ "${WORKER_STREAM_COUNT}" = 0 ]
        then
            export WORKER_STREAM_COUNT=3
        fi
        export ENCRYPTION_ACTIVATED="true"
        export FREE_IPA="true"
        export IS_PVC=true
    elif [ "${CLUSTER_TYPE}" = "all-services-pvc-ecs" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=4
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
        if [ "${WORKER_STREAM_COUNT}" = 0 ]
        then
            export WORKER_STREAM_COUNT=3
        fi
        export ENCRYPTION_ACTIVATED="true"
        export FREE_IPA="true"
        export IS_PVC=true
        if [ "${ECS_MASTER_COUNT}" = 0 ]
        then
            export ECS_MASTER_COUNT=1
        fi
        if [ "${ECS_WORKER_COUNT}" = 0 ]
        then
            export ECS_WORKER_COUNT=2
        fi
    elif [ "${CLUSTER_TYPE}" = "pvc" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=3
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
        export FREE_IPA="true"
        export IS_PVC=true
        if [ "${ECS_MASTER_COUNT}" = 0 ]
        then
            export ECS_MASTER_COUNT=1
        fi
        if [ "${ECS_WORKER_COUNT}" = 0 ]
        then
            export ECS_WORKER_COUNT=2
        fi
    elif [ "${CLUSTER_TYPE}" = "pvc-oc" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=3
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
        export FREE_IPA="true"
        export IS_PVC=true
    elif [ "${CLUSTER_TYPE}" = "streaming" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=4
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
        if [ "${WORKER_STREAM_COUNT}" = 0 ]
        then
            export WORKER_STREAM_COUNT=3
        fi
    elif [ "${CLUSTER_TYPE}" = "observability" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=3
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
    elif [ "${CLUSTER_TYPE}" = "cdh6" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=3
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
    elif [ "${CLUSTER_TYPE}" = "cdh6-enc-stream" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=3
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
        export ENCRYPTION_ACTIVATED="true"
    elif [ "${CLUSTER_TYPE}" = "cdh5" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=3
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
    elif [ "${CLUSTER_TYPE}" = "hdp2" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=3
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
    elif [ "${CLUSTER_TYPE}" = "hdp3" ]
    then
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=3
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
    else
        if [ "${MASTER_COUNT}" = 0 ]
        then
            export MASTER_COUNT=3
        fi
        if [ "${WORKER_COUNT}" = 0 ]
        then
            export WORKER_COUNT=3
        fi
    fi

fi

if [ -z ${DOMAIN_NAME} ]
then
    export DOMAIN_NAME="${CLUSTER_NAME}.onescript.vpc.com"
fi

# Split WHITELIST_IP
export WHIP_UNIQ=$( echo ${WHITELIST_IPS} | uniq )
export WHIP_ARRAY=( ${WHIP_UNIQ} )
export WHITELIST_IP=""
for ip in "${WHIP_ARRAY[@]}"; do
    WHITELIST_IP+="\"$ip/32\","
done
WHITELIST_IP=${WHITELIST_IP%,}

## Terraform files
export TF_FILE_TEMPLATE_PATH="terraform/${TF_FILE_TEMPLATE_NAME}"
export TF_TEMPLATE_HOSTS_FILE_PATH="terraform/${TF_FILE_TEMPLATE_NAME}/ids_hostname.tpl"
export TF_TEMPLATE_INTERNAL_HOSTS_FILE_PATH="terraform/${TF_FILE_TEMPLATE_NAME}/hosts_internal.tpl"

export TF_WORK_DIR="${TF_BASE_WORK_DIR}/terraform_${CLUSTER_NAME}"
export TF_INTERNAL_MACHINE_IDS_FILE=${TF_WORK_DIR}/internal_machine_ids
export TF_INTERNAL_HOSTS_FILE=${TF_WORK_DIR}/internal_etc_hosts
export TF_HOSTS_FILE=${TF_WORK_DIR}/external_etc_hosts
export CURRENT_DIR=$(pwd)

export YOUR_PUBLIC_KEY=$(cat ${PUBLIC_KEY_PATH})

# Prepare terraform files
mkdir -p ${TF_WORK_DIR}

envsubst < ${TF_FILE_TEMPLATE_PATH}/main.tf > ${TF_WORK_DIR}/main.tf
envsubst < ${TF_FILE_TEMPLATE_PATH}/outputs.tf > ${TF_WORK_DIR}/outputs.tf
envsubst < ${TF_FILE_TEMPLATE_PATH}/variables.tf > ${TF_WORK_DIR}/variables.tf
envsubst < ${TF_FILE_TEMPLATE_PATH}/providers.tf > ${TF_WORK_DIR}/providers.tf

cp ${TF_TEMPLATE_HOSTS_FILE_PATH} ${TF_WORK_DIR}/ids_hostname.tpl
cp ${TF_TEMPLATE_INTERNAL_HOSTS_FILE_PATH} ${TF_WORK_DIR}/hosts_internal.tpl

rm ${TF_HOSTS_FILE}
touch ${TF_HOSTS_FILE}
rm ${TF_INTERNAL_MACHINE_IDS_FILE}
touch ${TF_INTERNAL_MACHINE_IDS_FILE}
rm ${TF_INTERNAL_HOSTS_FILE}
touch ${TF_INTERNAL_HOSTS_FILE}

# Print Env variables
if [ "${DEBUG}" = "true" ]
then
    print_env_vars
fi



## Provision Machines and basic network
logger info "Start Provisionning Machines on the Cloud"

cd ${TF_WORK_DIR}
terraform init
terraform validate
terraform apply -auto-approve


# Get Terraform output
export VPC_ID=$(terraform output -json vpc_id | jq -r '.[0] | @sh ' | tr -d \' | sort | uniq)
export BASE_MASTERS=$(terraform output -json masters | jq -r '.[0] | @sh ' | tr -d \' | sort | uniq)
terraform output ip_hosts_masters >> ${TF_INTERNAL_MACHINE_IDS_FILE}
terraform output ip_internal_hosts_masters >> ${TF_INTERNAL_HOSTS_FILE}
export MASTER_IDS=$(terraform output -json masters_ids | jq -r '.[0] | @sh ' | sort | uniq)
export BASE_WORKERS=$(terraform output -json workers | jq -r '.[0] | @sh ' | tr -d \' | sort | uniq)
terraform output ip_hosts_workers >> ${TF_INTERNAL_MACHINE_IDS_FILE}
terraform output ip_internal_hosts_workers >> ${TF_INTERNAL_HOSTS_FILE}
export WORKER_IDS=$(terraform output -json workers_ids | jq -r '.[0] | @sh ' | sort | uniq)


export FREE_IPA_NODE=""
if [ ${FREE_IPA} = "true" ]
then
    export FREE_IPA_NODE=$(terraform output -json ipa | jq -r '.[0] | @sh ' | tr -d \' | sort | uniq)
    terraform output ip_hosts_ipa >> ${TF_INTERNAL_MACHINE_IDS_FILE}
    terraform output ip_internal_hosts_ipa >> ${TF_INTERNAL_HOSTS_FILE}
    export IPA_IDS=$(terraform output -json ipa_ids | jq -r '.[0] | @sh ' | sort | uniq)
fi

export KTS_NODE=""
if [ ${ENCRYPTION_ACTIVATED} = "true" ]
then
    export KTS_NODE=$(terraform output -json kts | jq -r '.[0] | @sh ' | tr -d \' | sort | uniq)
    terraform output ip_hosts_kts >> ${TF_INTERNAL_MACHINE_IDS_FILE}
    terraform output ip_internal_hosts_kts >> ${TF_INTERNAL_HOSTS_FILE}
    export KTS_IDS=$(terraform output -json kts_ids | jq -r '.[0] | @sh ' | sort | uniq)
fi

export BASE_WORKERS_STREAM=""
if [ ${WORKER_STREAM_COUNT} != 0 ]
then
    export BASE_WORKERS_STREAM=$(terraform output -json workers-stream | jq -r '.[0] | @sh ' | tr -d \' | sort | uniq)
    terraform output ip_hosts_worker_stream >> ${TF_INTERNAL_MACHINE_IDS_FILE}
    terraform output ip_internal_hosts_worker_stream >> ${TF_INTERNAL_HOSTS_FILE}
    export WORKER_STREAM_IDS=$(terraform output -json workers-stream_ids | jq -r '.[0] | @sh ' | sort | uniq)
fi

export ECS_MASTER_NODES=""
if [ ${ECS_MASTER_COUNT} != 0 ]
then
    export ECS_MASTER_NODES=$(terraform output -json ecs-master | jq -r '.[0] | @sh ' | tr -d \' | sort | uniq)
    export ECS_MASTER_NODE_1=$(echo $ECS_MASTER_NODES | cut -d' ' -f1 )
    terraform output ip_hosts_ecs_master >> ${TF_INTERNAL_MACHINE_IDS_FILE}
    terraform output ip_internal_hosts_ecs_master >> ${TF_INTERNAL_HOSTS_FILE}
    export ECS_MASTER_IDS=$(terraform output -json ecs-master_ids | jq -r '.[0] | @sh ' | sort | uniq)
fi

export ECS_WORKER_NODES=""
if [ ${ECS_WORKER_COUNT} != 0 ]
then
    export ECS_WORKER_NODES=$(terraform output -json ecs-worker | jq -r '.[0] | @sh ' | tr -d \' | sort | uniq)
    terraform output ip_hosts_ecs_worker >> ${TF_INTERNAL_MACHINE_IDS_FILE}
    terraform output ip_internal_hosts_ecs_worker >> ${TF_INTERNAL_HOSTS_FILE}
    export ECS_WORKER_IDS=$(terraform output -json ecs-worker_ids | jq -r '.[0] | @sh ' | sort | uniq)
fi

export MACHINE_IDS_SUM="${MASTER_IDS} ${WORKER_IDS} ${IPA_IDS} ${KTS_IDS} ${WORKER_STREAM_IDS} ${ECS_MASTER_IDS} ${ECS_WORKER_IDS}"
export MACHINES_IDS=$(echo $MACHINE_IDS_SUM | awk '{$1=$1};1' | sed 's/ /, /g' | sed s/\'/\"/g )

# Clean hosts file
sed -i'' -e 's/EOT//g' ${TF_INTERNAL_MACHINE_IDS_FILE}
sed -i'' -e 's/\"//g' ${TF_INTERNAL_MACHINE_IDS_FILE}
sed -i'' -e 's/\<//g' ${TF_INTERNAL_MACHINE_IDS_FILE}
sed -i'' -e '/^$/d' ${TF_INTERNAL_MACHINE_IDS_FILE}
sed -i'' -e 's/EOT//g' ${TF_INTERNAL_HOSTS_FILE}
sed -i'' -e 's/\"//g' ${TF_INTERNAL_HOSTS_FILE}
sed -i'' -e 's/\<//g' ${TF_INTERNAL_HOSTS_FILE}
sed -i'' -e '/^$/d' ${TF_INTERNAL_HOSTS_FILE}

cd ${CURRENT_DIR}

logger success "Finish Provisionning Machines on the Cloud"


#### Creation of Network Advanced requirements: DNS records, Elastic Ips etc...

logger info "Start Provisioning Advanced Network Requirements"

# Create a map of hostname to machine IDs
export FILE_CONTAINING_HOST_NAME_MACHINES_ID_MAP=$(mktemp)
while IFS= read -r line; do
    HOSTNAME_LINE=$( echo $line | cut -d' ' -f 2 )
    ID_LINE=$( echo $line | cut -d' ' -f 1 )
    echo "\"$HOSTNAME_LINE\" = \"$ID_LINE\"" >> $FILE_CONTAINING_HOST_NAME_MACHINES_ID_MAP  
done < "$TF_INTERNAL_MACHINE_IDS_FILE"
export HOST_NAME_MACHINES_ID_MAP=$(cat $FILE_CONTAINING_HOST_NAME_MACHINES_ID_MAP)

# Create a record for: (*.)console-cdp.apps.ECS_MASTER_1 to its IP
if [ "$IS_PVC" == "true" ] ; then
    export ECS_MASTER_1_IP=$( grep $ECS_MASTER_NODE_1 ${TF_INTERNAL_HOSTS_FILE} | cut -d' ' -f1)
fi

# Create DNS records for ALL machines
export FIRST_MASTER_IP=$(head -1 ${TF_INTERNAL_HOSTS_FILE} | cut -d ' ' -f 1)
export FILE_CONTAINING_HOSTNAME_IP_MAP=$(mktemp)
# Create a map in terraform style of hostname = IP for all nodes so it will be injected in route53 map
while IFS= read -r line; do
    HOSTNAME_LINE=$( echo $line | cut -d' ' -f 2 )
    IP_LINE=$( echo $line | cut -d' ' -f 1 )
    echo "\"$HOSTNAME_LINE\" = \"$IP_LINE\"" >> $FILE_CONTAINING_HOSTNAME_IP_MAP  
done < "$TF_INTERNAL_HOSTS_FILE"
export HOST_NAME_IP_MAP=$(cat $FILE_CONTAINING_HOSTNAME_IP_MAP)

mkdir -p ${TF_WORK_DIR}/dns_records
envsubst < ${TF_FILE_TEMPLATE_PATH}/dns_records/main.tf > ${TF_WORK_DIR}/dns_records/main.tf
envsubst < ${TF_FILE_TEMPLATE_PATH}/dns_records/outputs.tf > ${TF_WORK_DIR}/dns_records/outputs.tf
envsubst < ${TF_FILE_TEMPLATE_PATH}/providers.tf > ${TF_WORK_DIR}/dns_records/providers.tf
cp ${TF_FILE_TEMPLATE_PATH}/dns_records/hosts_eip.tpl ${TF_WORK_DIR}/dns_records/hosts_eip.tpl
cd ${TF_WORK_DIR}/dns_records
terraform init
terraform validate
terraform apply -auto-approve
terraform output hosts_ips >> ${TF_HOSTS_FILE}
sed -i'' -e 's/EOT//g' ${TF_HOSTS_FILE}
sed -i'' -e 's/\"//g' ${TF_HOSTS_FILE}
sed -i'' -e 's/\<//g' ${TF_HOSTS_FILE}
sed -i'' -e '/^$/d' ${TF_HOSTS_FILE}
cd ${CURRENT_DIR}

logger success "Finished Provisioning Advanced Netwoork Requirements"

# Add this line to /etc/hosts: console-cdp.apps.ecs-master-01.firstpvc.onescript.vpc.com
EXTRA_ECS_LINE=""
if [ "$IS_PVC" == "true" ] ; then
    if [ ! -z ${ECS_MASTER_1_IP} ]; then
        ECS_MASTER_1_EXT_IP=$(grep ${ECS_MASTER_NODE_1} ${TF_HOSTS_FILE} | cut -d' ' -f1 )
        EXTRA_ECS_LINE="${ECS_MASTER_1_EXT_IP} console-cdp.apps.${ECS_MASTER_NODE_1}"
    fi
fi

## Get IPs 
export MACHINES_WITH_IPS=$(cat ${TF_HOSTS_FILE}) 

if pcre2grep -q -M "$MACHINES_WITH_IPS" /etc/hosts; then
    logger info "Cluster already exists in /etc/hosts, continuing...";
else
    logger info ""
    logger info:cyan " Copy this to your #underline:/etc/hosts#end_underline file (this requires root privileges): "
    echo ""
    echo "## Cluster ${CLUSTER_NAME} ##"
    echo "${MACHINES_WITH_IPS}"
    echo "${EXTRA_ECS_LINE}"
    echo ""
    read -p "Press Enter to continue:"
    echo ""
fi

# Sleep 5 secs to make sure dns records propagates
sleep 5

export NODES=( ${BASE_MASTERS} ${BASE_WORKERS} ${FREE_IPA_NODE} ${KTS_NODE} ${BASE_WORKERS_STREAM} ${ECS_MASTER_NODES} ${ECS_WORKER_NODES} )

### Launch Machine prerequisites in the Cloud
if [ "${APPLY_CLOUD_MACHINES_PREREQUISITES}" = "true" ]
then
    logger info " Applying prerequisites on nodes depending on Cloud Provider "
    
    for i in ${!NODES[@]}
    do   
        logger info "Applying Prerequisites for node: #bold:${NODES[$i]}"

        SSHKey=`ssh-keyscan ${NODES[$i]} 2> /dev/null`
        echo $SSHKey >> ~/.ssh/known_hosts

        if [ "${CLOUD_PROVIDER}" = "AWS" ]
        then
            # Make sure that restarts does not affect hostname and set hostname
            ssh -q -i ${PRIVATE_KEY_PATH} ${INITIAL_NODE_USER}@${NODES[$i]} "sudo hostnamectl set-hostname ${NODES[$i]}"
            ssh -q -i ${PRIVATE_KEY_PATH} ${INITIAL_NODE_USER}@${NODES[$i]} "sudo sed -i 's/preserve_hostname\:[[:space:]]false/preserve_hostname: true/g' /etc/cloud/cloud.cfg"
            # Setup password-less ssh for root user of your local user
            ssh -q -i ${PRIVATE_KEY_PATH} ${INITIAL_NODE_USER}@${NODES[$i]} "sudo sed -i 's/disable_root\:[[:space:]]true/disable_root: false/g' /etc/cloud/cloud.cfg"
            ssh -q -i ${PRIVATE_KEY_PATH} ${INITIAL_NODE_USER}@${NODES[$i]} "sudo echo "${YOUR_PUBLIC_KEY}" >> /home/${INITIAL_NODE_USER}/.ssh/authorized_keys"
            ssh -q -i ${PRIVATE_KEY_PATH} ${INITIAL_NODE_USER}@${NODES[$i]} "sudo cp /home/${INITIAL_NODE_USER}/.ssh/authorized_keys /root/.ssh/authorized_keys"
            # Setup /etc/hosts with new hostname
            scp -q -i ${PRIVATE_KEY_PATH} ${TF_INTERNAL_HOSTS_FILE} ${INITIAL_NODE_USER}@${NODES[$i]}:/tmp/internal_etc_hosts
            ssh -q -i ${PRIVATE_KEY_PATH} root@${NODES[$i]} "sudo cat /tmp/internal_etc_hosts >> /etc/hosts"
            # Setup Fake rhel to avoid CM rejections of nodes
            if [ "${OS_VERSION}" == "8.8" ] && [ "${OS}" == "rhel" ] ; then
              ssh -q -i ${PRIVATE_KEY_PATH} root@${NODES[$i]} "sudo echo 'Red Hat Enterprise Linux release 8.8 (Ootpa)' > /etc/redhat-release"
              ssh -q -i ${PRIVATE_KEY_PATH} root@${NODES[$i]} "sudo echo 'ID=\"rhel\"' >> /etc/os-release"
            fi
            # Install python 3 for ansible deployment
            ssh -q -i ${PRIVATE_KEY_PATH} root@${NODES[$i]} "sudo yum -y install python3 >/dev/null 2>&1 "
            # Make a reboot of machines to make sure all previous prereqs are applied
            ssh -q -i ${PRIVATE_KEY_PATH} root@${NODES[$i]} "sudo reboot"
        fi

        logger info "Finished Prerequisites for node: #bold:${NODES[$i]}"

    done
fi

# Check all machines are available
for i in ${!NODES[@]}
do
    while true ; do
        if ssh root@${NODES[$i]} true ; then
            logger info "Node #bold:${NODES[$i]} is alive"
            break
        fi
        sleep 5
    done
done

logger success " Finished applying prerequisites"


# Prepare and Launch command to setup cluster
logger info "Launching Setup of cluster"

logger info "Launching Command:"
echo "
./setup-cluster.sh ${ALL_PARAMETERS} \
  --is-reboot-required=true \
  --setup-etc-hosts=false \
  --extra-ecs-safety-valve=true \
  --node-user='root' \
  --node-key="${PRIVATE_KEY_PATH}" \
  --nodes-base="${BASE_MASTERS} ${BASE_WORKERS} ${BASE_WORKERS_STREAM}" \
  --node-ipa="${FREE_IPA_NODE}" \
  --nodes-kts="${KTS_NODE}" \
  --nodes-ecs="${ECS_MASTER_NODES} ${ECS_WORKER_NODES}"
"

./setup-cluster.sh ${ALL_PARAMETERS} \
  --is-reboot-required=true \
  --setup-etc-hosts=false \
  --extra-ecs-safety-valve=true \
  --node-user='root' \
  --node-key="${PRIVATE_KEY_PATH}" \
  --nodes-base="${BASE_MASTERS} ${BASE_WORKERS} ${BASE_WORKERS_STREAM}" \
  --node-ipa="${FREE_IPA_NODE}" \
  --nodes-kts="${KTS_NODE}" \
  --nodes-ecs="${ECS_MASTER_NODES} ${ECS_WORKER_NODES}"