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
<<<<<<< HEAD

=======
>>>>>>> aab1f37ead5e11993e4324ec5aa24e0c0a70e2c1
