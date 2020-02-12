#!/bin/bash

sudo service webodm-nginx stop
sudo service webodm-gunicorn stop
sudo service webodm-celery stop
sudo service webodm-celerybeat stop
sudo service postgresql stop
sudo service redis-server stop
sudo service clusterodm stop
sudo service micmac stop
sudo service nodeodm stop
