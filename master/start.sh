#!/bin/sh

/usr/bin/suricata -c suricata.yaml -i eth0 -i eth1 &
podman system service --time=0 unix:///tmp/podman.sock &

cd honeypots
python3 main.py --setup ssh --config config.json --termination-strategy signal &
