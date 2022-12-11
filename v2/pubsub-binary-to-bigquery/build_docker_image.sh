#!/usr/bin/env bash
# !!!Run from repository root

set -euox pipefail

export JAVA_HOME=/usr/local/Cellar/openjdk@11/11.0.16.1_1/libexec/openjdk.jdk/Contents/Home

mvn spotless:apply

export PROJECT=com-ridedott-data-development
export REPOSITORY=dataflow-template-docker
export IMAGE_NAME=pubsub-binary-to-bigquery
# Artifact registry format: LOCATION-docker.pkg.dev/PROJECT-ID/REPOSITORY/IMAGE
export TARGET_GCR_IMAGE=europe-west1-docker.pkg.dev/${PROJECT}/${REPOSITORY}/${IMAGE_NAME}
export BASE_CONTAINER_IMAGE=gcr.io/dataflow-templates-base/java11-template-launcher-base
export BASE_CONTAINER_IMAGE_VERSION=latest
export APP_ROOT=/template/pubsub-proto-to-bigquery
export COMMAND_SPEC=${APP_ROOT}/resources/pubsub-proto-to-bigquery-command-spec.json

mvn clean package -Dimage=${TARGET_GCR_IMAGE} \
                  -Dbase-container-image=${BASE_CONTAINER_IMAGE} \
                  -Dbase-container-image.version=${BASE_CONTAINER_IMAGE_VERSION} \
                  -Dapp-root=${APP_ROOT} \
                  -Dcommand-spec=${COMMAND_SPEC} \
                  -pl v2/pubsub-binary-to-bigquery -am
#
#echo "sleep for 10 seconds"
#sleep 10

# TODO Update the image field in v2/pubsub-proto-to-bigquery-image-spec-template.json
# gsutil cp v2/pubsub-binary-to-bigquery/docs/PubSubProtoToBigQuery/pubsub-proto-to-bigquery-image-spec-template.json gs://com-ridedott-data-development-bq-tmp/pubsub-proto-to-bigquery-image-spec-template.json
# bq --format=prettyjson show -schema com-ridedott-data-staging:user_dalei.oak_telemetry_test >oak_telemetry_test.json
# gsutil cp oak_telemetry_test.json gs://com-ridedott-data-development-bq-tmp/oak_telemetry_test.json

# Access Denied: Dataset com-ridedott-data-staging:user_dalei: Permission bigquery.datasets.get denied on dataset com-ridedott-data-staging:user_dalei (or it may not exist).
gcloud dataflow flex-template run "oak-telemetry-test-`date +%Y%m%d-%H%M%S`" \
 --template-file-gcs-location=gs://com-ridedott-data-development-bq-tmp/pubsub-proto-to-bigquery-image-spec-template.json \
 --service-account-email=composer@com-ridedott-data-development.iam.gserviceaccount.com \
 --max-workers=1 \
 --project=com-ridedott-data-development \
 --region=europe-west1 \
 --parameters protoSchemaPath="gs://com-ridedott-data-development-bq-tmp/telemetry_schema.pb" \
 --parameters fullMessageName="telemetry.Telemetry" \
 --parameters inputSubscription="projects/com-ridedott-data-development/subscriptions/event-vehicle-oak-telemetry-sub" \
 --parameters outputTopic="projects/com-ridedott-data-development/topics/invalid-event-vehicle-oak-telemetry" \
 --parameters outputTableSpec="com-ridedott-data-staging:user_dalei.oak_telemetry_test" \
 --parameters bigQueryTableSchemaPath="gs://com-ridedott-data-development-bq-tmp/oak_telemetry_test.json" \
 --parameters javascriptTextTransformGcsPath="gs://com-ridedott-data-development-bq-tmp/parse_vehicle_metadata.js" \
 --parameters javascriptTextTransformFunctionName="transform"
