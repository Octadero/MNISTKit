#!/bin/sh

sourcekitten doc --spm-module MNISTKit > Documentation/MNISTKit.json

jazzy --config Documentation/MNISTKit.yaml

rm Documentation/MNISTKit.json

