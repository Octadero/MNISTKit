#!/bin/sh

sourcekitten doc --spm-module MNISTKit > Documentation/MNISTKit.json

jazzy --config Documentation/MNISTKit.yaml

rm Documentation/MNISTKit.json
# Add access bin/gsutil iam ch allUsers:objectViewer gs://api.octadero.com
# Upload on webserver
# /server/repository/google-cloud-sdk/bin/gsutil -m cp -r Documentation/MNISTKit gs://api.octadero.com
