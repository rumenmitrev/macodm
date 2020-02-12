#!/bin/bash

sudo service webodm-nginx restart
sudo service webodm-gunicorn restart
sudo service webodm-celery restart
sudo service webodm-celerybeat restart
sudo service postgresql restart
sudo service redis-server restart
sudo service clusterodm restart
sudo service micmac restart
sudo service nodeodm restart

