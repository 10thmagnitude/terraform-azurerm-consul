#!/bin/bash
# This script is meant to be run in the Custom Data of each Azure Instance while it's booting. The script uses the
# run-consul script to configure and start Consul in server mode. Note that this script assumes it's running in an Image
# built from the Packer template in examples/consul-image/consul.json.

set -e

# Send the log output from this script to custom-data.log, syslog, and the console
exec > >(tee /var/log/custom-data.log|logger -t custom-data -s 2>/dev/console) 2>&1

systemctl daemon-reload
systemctl start consul.service
systemctl enable consul.service
