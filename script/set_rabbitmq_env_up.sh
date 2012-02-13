#!/bin/sh

rabbitmqctl add_vhost "travisci.development"
rabbitmqctl add_user travisci_hub travisci_hub_password

rabbitmqctl set_permissions -p "travisci.development" travisci_hub ".*" ".*" ".*"
rabbitmqctl set_permissions -p "travisci.development" guest      ".*" ".*" ".*"
