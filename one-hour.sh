#!/bin/bash -e
curl -o usgs_ds https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson
current_time=$(date +"%Y%m%d-%H%M%S")
dataset_name=usgs_dataset.$current_time
jq -r '.features[] | "\(.geometry.coordinates[1])|\(.geometry.coordinates[0])|\(.properties.place)|\(.properties.mag)"' usgs_ds > $dataset_name
cliapp -i $dataset_name --dataset-name latest
cliapp -i $dataset_name --dataset-name $dataset_name
find ~ -name 'usgs_dataset*' -mtime +1 -delete
