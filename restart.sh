#!/bin/bash

sudo service webodm-nginx restart
sudo service webodm-gunicorn restart
sudo service webodm-celery restart
sudo service webodm-celerybeat restart