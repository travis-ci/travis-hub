#!/bin/sh

rabbitmqctl add_vhost "travis.development"
rabbitmqctl add_user travis_hub travis_hub_password

rabbitmqctl set_permissions -p "travis.development" travis_hub ".*" ".*" ".*"
rabbitmqctl set_permissions -p "travis.development" guest      ".*" ".*" ".*"
