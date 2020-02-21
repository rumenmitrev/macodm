#!/bin/bash

install(){
  CPUS=$(grep -c ^processor /proc/cpuinfo)
  
  sudo apt update -y
  sudo apt upgrade -y
  sudo apt install -y virtualenv curl python-setuptools nginx-core nginx build-essential gcc g++ cmake python3-dev python-virtualenv redis-server binutils libproj-dev grass-core git swapspace htop libboost-dev libboost-program-options-dev exiftool python-shapely exiv2 imagemagick xmlstarlet libjpeg-progs python-geojson python3-pip p7zip-full python-matplotlib python-numpy python-pil python-scipy cython python-skimage

  cd ~
  sudo curl --silent --location https://deb.nodesource.com/setup_10.x | sudo bash -
  sudo apt install -y nodejs python-gdal
  sudo npm install -g npm
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt update
  sudo apt install -y postgresql-9.6
  sudo apt install -y postgresql-9.6-postgis-2.4 postgresql-9.6-postgis-2.5-scripts postgresql-9.6-postgis-2.5
  sudo apt install -y python-psycopg2
  
  ## FOR BIONIC
  #sudo sh -c 'echo "deb http://security.ubuntu.com/ubuntu xenial-security main" > /etc/apt/sources.list.d/xenial.list'
  #sudo apt-get update
  #sudo apt-get install -y -qq libjasper1 libjasper-dev
  #sudo apt-get upgrade -y
  
  # Add nginx, grass, other requirements
  sudo systemctl stop nginx
  sudo systemctl disable nginx 
 
  cd /
  sudo git clone --depth 1 https://github.com/OpenDroneMap/OpenDroneMap.git code
  sudo git clone --depth 1 https://github.com/OpenDroneMap/node-OpenDroneMap.git www
  sudo git clone --depth 1 https://github.com/OpenDroneMap/WebODM.git webodm
  sudo git clone https://github.com/OpenDroneMap/ClusterODM clusterodm
  #sudo git clone https://github.com/dronemapper-io/NodeMICMAC.git micmac
  #git clone https://github.com/rumenmitrev/macodm.git ~/macodm
  sudo git clone https://github.com/rumenmitrev/NodeMICMAC.git micmac
  #micmac dep
  sudo mkdir /staging
  sudo mkdir /home/drnmppr-micmac
  sudo git clone https://github.com/micmacIGN/micmac.git /home/drnmppr-micmac
  sudo git clone https://github.com/pierotofy/LAStools /staging/LAStools
  sudo git clone https://github.com/pierotofy/PotreeConverter /staging/PotreeConverter
  sudo chown $(whoami) -R /www /code /webodm /clusterodm /staging /micmac /home/drnmppr-micmac
  
  #sudo chmod +x /code/configure_18_04.sh
  #sudo bash /code/configure_18_04.sh install
  sudo bash /code/configure.sh install
  
  sudo ln -s /code/SuperBuild/install/bin/entwine /usr/bin/entwine
  sudo ln -s /code/SuperBuild/install/lib/libpdal_util.so.8 /usr/lib/libpdal_util.so.8
  sudo ln -s /code/SuperBuild/install/lib/libentwine.so.2 /usr/lib/libentwine.so.2
  sudo ln -s /code/SuperBuild/install/lib/libpdal_base.so.8 /usr/lib/libpdal_base.so.8
  
  sudo ln -s /code/SuperBuild/install/bin/pdal /usr/bin/pdal	
  
  
  cd /www
  npm install


  sudo service postgresql start
  sudo -u postgres bash -c "psql -c \"CREATE USER postgres WITH PASSWORD 'postgres';\""
  sudo -u postgres bash -c "psql -c \"ALTER USER postgres PASSWORD 'postgres';\""
  sudo -u postgres bash -c "psql -c \"ALTER ROLE postgres WITH SUPERUSER;\""
  sudo -u postgres createdb -O postgres webodm_dev -E utf-8
  sudo -u postgres bash -c "psql -d webodm_dev -c \"CREATE EXTENSION postgis;\""
  sudo -u postgres bash -c "psql -d webodm_dev -c \"SET postgis.enable_outdb_rasters TO True;\""
  sudo -u postgres bash -c "psql -d webodm_dev -c \"SET postgis.gdal_enabled_drivers TO 'GTiff';\"" 

  cd /webodm

  # Setup virtualenv
  virtualenv -p python3 python3-venv
  source python3-venv/bin/activate

  echo "DATABASES = {
      'default': {
          'ENGINE': 'django.contrib.gis.db.backends.postgis',
          'NAME': 'webodm_dev',
          'USER': 'postgres',
          'PASSWORD': 'postgres',
          'HOST': 'localhost',
          'PORT': '5432',
      }
  }" > /webodm/webodm/local_settings.py
  
  pip install -r requirements.txt
  
  # Build assets
  sudo npm install -g webpack
  sudo npm install -g webpack-cli
  sudo rm /usr/bin/webpack-cli
  sudo ln -s $(which webpack) /usr/bin/webpack-cli

  echo "
worker_processes 1;

# Change this if running outside docker!
user odm odm;
pid /run/nginx.pid;
error_log /webodm/nginx.error.log;

events {
  worker_connections 1024; # increase if you have lots of clients
  accept_mutex off; # set to 'on' if nginx worker_processes > 1
  use epoll;
}

http {
  include /etc/nginx/mime.types;

  # fallback in case we can't determine a type
  default_type application/octet-stream;
  access_log /webodm/nginx.access.log combined;
  sendfile on;

  upstream app_server {
    # fail_timeout=0 means we always retry an upstream even if it failed
    # to return a good HTTP response

    # for UNIX domain socket setups
    server unix:/webodm/gunicorn.sock fail_timeout=0;
  }

  server {
    listen 80 deferred;
    client_max_body_size 0;

    server_name localhost;

    keepalive_timeout 5;

    proxy_connect_timeout 60s;
    proxy_read_timeout 300000s;

    # path for static files
    location /static {
      root /webodm/build;
    }

    # path for certain media files that don't need permissions enforced
    location /media/CACHE {
      root /webodm/app;
    }
    location /media/settings {
      autoindex on;
      root /webodm/app;
    }

    location / {
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

      # enable this if and only if you use HTTPS
      # proxy_set_header X-Forwarded-Proto https;
      proxy_set_header Host \$host;

      # we don't want nginx trying to do something clever with
      # redirects, we set the Host: header above already.
      proxy_redirect off;
      proxy_pass http://app_server;
    }
  }
}

" > /webodm/nginx/nginx.conf
  
  sudo chown -R $(whoami):$(whoami) /webodm
  npm install
  webpack --mode production
  python manage.py collectstatic --noinput
  python manage.py migrate
  bash app/scripts/plugin_cleanup.sh
  echo "from app.plugins import build_plugins;build_plugins()" | python manage.py shell
  
  sudo chown -R $(whoami):$(whoami) /clusterodm
  cd /clusterodm
  npm install  
  echo "
[Unit]
Description=Start ClusterODM Service

[Service]
Type=simple
PIDFile=/run/clusterodm.pid
User=odm
Group=odm
WorkingDirectory=/clusterodm
ExecStart=/usr/bin/node index.js -p 3001 --odm_path /code
ExecStop=/bin/kill -s QUIT $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target

" > /clusterodm/clusterodm.service
  
  
  ## dep and micmac
  sudo -H pip install utm
  cd /staging/LAStools/LASzip
  mkdir build
  cd build
  cmake -DCMAKE_BUILD_TYPE=Release ..
  make -j$CPUS
  ## potreeeconvertor
  cd /staging/PotreeConverter
  mkdir build
  cd build
  cmake -DCMAKE_BUILD_TYPE=Release -DLASZIP_INCLUDE_DIRS=/staging/LAStools/LASzip/dll -DLASZIP_LIBRARY=/staging/LAStools/LASzip/build/src/liblaszip.a ..
  make -j$CPUS && sudo make install
  cd /micmac
  npm install
  #compile micmac
  cd /home/drnmppr-micmac
  mkdir build
  cd build
  cmake ../
  make install -j$CPUS
  
  echo "
[Unit]
Description=Start Micmac Service

[Service]
Type=simple
PIDFile=/run/micmac.pid
User=odm
Group=odm
WorkingDirectory=/micmac
ExecStart=/usr/bin/node index.js -p 3002 --odm_path /micmac/dm
ExecStop=/bin/kill -s QUIT $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target

" > /micmac/micmac.service  
  
  
  # Create user
  sudo useradd -m odm
  sudo chown -R odm /code /www /webodm /home/odm /clusterodm /staging /micmac /home/drnmppr-micmac

  
  # Add processing node
  cd /webodm
  echo "from nodeodm.models import ProcessingNode; ProcessingNode.objects.update_or_create(hostname='node-odm-1', defaults={'hostname': 'localhost', 'port': 3000})" | python manage.py shell
  echo "from nodeodm.models import ProcessingNode; ProcessingNode.objects.update_or_create(hostname='micmac', defaults={'hostname': 'localhost', 'port': 3002})" | python manage.py shell

  
  ##Expand file system to get entire disk at boot
  ##sudo cp ~/resizefs_local_premount_vda /etc/initramfs-tools/scripts/local-premount/resizefs
  #sudo cp ~/resizefs_local_premount /etc/initramfs-tools/scripts/local-premount/resizefs
  #sudo cp ~/resizefs_hooks /etc/initramfs-tools/hooks/resizefs
  #sudo chmod 755 /etc/initramfs-tools/scripts/local-premount/resizefs
  #sudo chmod 755 /etc/initramfs-tools/hooks/resizefs
  #sudo update-initramfs -u
  

  #MICMAC docker
  #cd ~
  #curl -fsSL https://get.docker.com -o get-docker.sh
  #sh get-docker.sh
  #sudo docker run -d -p 3002:3000 dronemapper/node-micmac
  #sudo sed -i '12a docker run -d -p 3002:3000 dronemapper/node-micmac' /etc/rc.local
 
  pip3 install --upgrade pip && pip3 install 'Cython>= 0.23.4' && pip3 install numpy && pip3 install 'scikit-image<0.15' && pip3 install opencv-python rasterio geojson
  echo vm.overcommit_memory = 1 | sudo tee -a /etc/sysctl.conf && sysctl -p 
  # Link services
  sudo systemctl enable /www/services/nodeodm.service
  sudo systemctl enable /webodm/service/webodm-nginx.service
  sudo systemctl enable /webodm/service/webodm-gunicorn.service
  sudo systemctl enable /webodm/service/webodm-celery.service
  sudo systemctl enable /webodm/service/webodm-celerybeat.service
  sudo systemctl enable /clusterodm/clusterodm.service
  sudo systemctl enable /micmac/micmac.service
  
  sudo service webodm-nginx start
  sudo service webodm-gunicorn start
  sudo service webodm-celery start
  sudo service webodm-celerybeat start
  sudo service nodeodm start
  sudo service clusterodm start
  sudo service micmac start
  
  
  deactivate
  sudo reboot
}

congrats(){
  echo -e "\033[92m"      
  echo "Congratulations! └@(･◡･)@┐"
  echo ==========================
  echo -e "\033[39m"
  echo "If there are no errors, WebODM should be up and running!"
  echo -e "\033[93m"
  echo -e "\033[39m"
}
update(){
  echo -e "\033[92m"      
  echo "Ko sha praim! └@(･◡･)@┐"
  echo ==========================
  echo -e "\033[39m"
  echo "If there are no errors, WebODM should be up and running!"
  echo -e "\033[93m"
  echo -e "\033[39m"
}

if [ -e /webodm ]; then
  update
else
  install
fi
congrats
exit 0
#for potreeconverter
#sudo vi /etc/environment < /staging/PotreeConverter/build/PotreeConverter
