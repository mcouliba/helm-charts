#!/bin/bash

DIRECTORY=`dirname $0`
display_usage() {
    echo -e "Usage: $0 [arguments]"
}

if (($# == 0))
then
    display_usage
    exit 1
fi

lflag=false
sflag=false
nflag=false

while getopts ":hl:s:n:" option
do
    case ${option} in
        h)
            display_usage
            exit 0
            ;;
        l)
            lflag=true
            LABELS=${OPTARG}
            ;;
        s)
            sflag=true
            SERVICE=${OPTARG}
            TEMPLATE_DIR=${DIRECTORY}/../${SERVICE}/templates
            ;;
        n)
            nflag=true
            NAMESPACE=${OPTARG}
            ;;
        \?)
            display_usage
            exit 1
            ;;
        :)
            display_usage
            exit 1
            ;;
        *)
            display_usage
            exit 1
            ;;
    esac
done

if ! ${lflag} || ! ${sflag} || ! ${nflag}
then
    echo "-s and -l and -n options are mandatory" >&2
    display_usage
    exit 1
fi

exportCR() {
    RESOURCE_TYPE=$1
    RESOURCE_YAML=${TEMPLATE_DIR}/${RESOURCE_TYPE}.yaml

    oc get ${RESOURCE_TYPE} -n ${NAMESPACE} -l${LABELS} -o yaml --ignore-not-found > ${RESOURCE_YAML}
    echo -e "Exported ${RESOURCE_TYPE} from ${NAMESPACE} into ${RESOURCE_YAML}"
}

cleanGenericCR() {
    RESOURCE_TYPE=$1
    RESOURCE_YAML=${TEMPLATE_DIR}/${RESOURCE_TYPE}.yaml

    if [ -s ${RESOURCE_YAML} ]
    then
        yq delete --inplace  ${RESOURCE_YAML} items[*].metadata.namespace
        yq delete --inplace  ${RESOURCE_YAML} items[*].metadata.uid
        yq delete --inplace  ${RESOURCE_YAML} items[*].metadata.selfLink
        yq delete --inplace  ${RESOURCE_YAML} items[*].metadata.creationTimestamp
        yq delete --inplace  ${RESOURCE_YAML} items[*].metadata.resourceVersion
        yq delete --inplace  ${RESOURCE_YAML} items[*].metadata.ownerReferences
        yq delete --inplace  ${RESOURCE_YAML} items[*].metadata.generation
        yq delete --inplace  ${RESOURCE_YAML} items[*].metadata.managedFields
        yq delete --inplace  ${RESOURCE_YAML} items[*].status
    fi
}

cleanSpecificCR() {
    RESOURCE_TYPE=$1
    RESOURCE_YAML=${TEMPLATE_DIR}/${RESOURCE_TYPE}.yaml

    if [ -s ${RESOURCE_YAML} ]
    then
        case ${RESOURCE_TYPE} in
            deployment)
                yq delete --inplace  ${RESOURCE_YAML} items[*].metadata.annotations.[deployment.kubernetes.io/revision]
                yq delete --inplace  ${RESOURCE_YAML} items[*].metadata.annotations.[image.openshift.io/triggers]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.initContainers
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].command
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].args
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].volumeMounts[0]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].volumeMounts[0]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].volumeMounts[0]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].env[0]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].env[0]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].env[0]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].env[0]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].env[0]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].env[0]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.containers[0].env[0]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.volumes[0]
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.template.spec.volumes[0]
                sed -i ".bck" 's#^\(.*image-registry\.openshift-image-registry\.svc:5000\)/.*/\(.*\)\(@.*\)$#\1/{{ .Release.Namespace }}/\2#g' ${RESOURCE_YAML}
                rm "${RESOURCE_YAML}.bck"
                ;;
            service)
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.clusterIP
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.clusterIPs
                ;;
            route)
                yq delete --inplace  ${RESOURCE_YAML} items[*].spec.host
                yq delete --inplace  ${RESOURCE_YAML} items[*].status.ingress[*].conditions[*].lastTransitionTime
                yq delete --inplace  ${RESOURCE_YAML} items[*].status.ingress[*].host
                yq delete --inplace  ${RESOURCE_YAML} items[*].status.ingress[*].routerCanonicalHostname
                yq delete --inplace  ${RESOURCE_YAML} items[*].status.ingress[*].routerName
                yq delete --inplace  ${RESOURCE_YAML} items[*].status.ingress[*].wildcardPolicy
                ;;
            imagestream)
                ;;
            pipeline)
                sed -i ".bck" 's@^\(.*image-registry\.openshift-image-registry\.svc:5000\)/.*/\(.*\)$@\1/{{ .Release.Namespace }}/\2@g' ${RESOURCE_YAML}
                rm "${RESOURCE_YAML}.bck"
                ;;
            configmap)
                ;;
            secret)
                ;;
        esac
    fi    
        
}

declare -a RESOURCES=("deployment" "service" "route" "imagestream" "pipeline" "configmap" "secret")

for RESOURCE in "${RESOURCES[@]}"
do
    exportCR ${RESOURCE}
    cleanGenericCR ${RESOURCE}
    cleanSpecificCR ${RESOURCE}
done