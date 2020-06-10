#!/bin/bash

  CPUS=$(grep -c ^processor /proc/cpuinfo)
  
  sudo apt update
  sudo apt upgrade
  sudo apt install -y curl python-setuptools build-essential gcc g++ cmake binutils libproj-dev git swapspace htop libboost-dev libboost-program-options-dev exiftool python-shapely exiv2 imagemagick xmlstarlet libjpeg-progs python-pip python3-pip zip
  python3 -m pip install --upgrade pip
  cd ~
  sudo curl --silent --location https://deb.nodesource.com/setup_10.x | sudo bash -
  sudo apt install -y nodejs python-gdal
  sudo npm install -g npm
  


 
  cd /
  #sudo git clone https://github.com/OpenDroneMap/WebODM --config core.autocrlf=input --depth 1 webodm
  sudo git clone --depth 1 https://github.com/OpenDroneMap/OpenDroneMap.git code
  sudo git clone --depth 1 https://github.com/OpenDroneMap/node-OpenDroneMap.git www
  #sudo git clone https://github.com/OpenDroneMap/ClusterODM clusterodm
  #sudo git clone https://github.com/dronemapper-io/NodeMICMAC.git micmac
  #sudo git clone https://github.com/rumenmitrev/NodeMICMAC.git micmac
  #micmac dep
  #sudo mkdir /staging
  #sudo mkdir /home/drnmppr-micmac
  #sudo git clone https://github.com/micmacIGN/micmac.git /home/drnmppr-micmac
  #sudo git clone https://github.com/pierotofy/LAStools /staging/LAStools
  #sudo git clone https://github.com/pierotofy/PotreeConverter /staging/PotreeConverter
  #sudo chown $(whoami) -R /www /code /clusterodm /staging /micmac /home/drnmppr-micmac /webodm
  
  #python3 -m pip install --user 'Cython>= 0.23.4' numpy 'scikit-image<0.15'  opencv-python rasterio geojson
  pip install --upgrade pip
  pip install --user pytz
  python -m  pip install --user -r /code/requirements.txt
  sudo bash /code/configure.sh install

  sudo ln -s /code/SuperBuild/install/bin/entwine /usr/bin/entwine
  sudo ln -s /code/SuperBuild/install/lib/libpdal_util.so.8 /usr/lib/libpdal_util.so.8
  sudo ln -s /code/SuperBuild/install/lib/libentwine.so.2 /usr/lib/libentwine.so.2
  sudo ln -s /code/SuperBuild/install/lib/libpdal_base.so.8 /usr/lib/libpdal_base.so.8
  sudo ln -s /code/SuperBuild/install/bin/pdal /usr/bin/pdal	
  
  
  cd /www
  npm install

  #cd /clusterodm
  #npm install  
  #echo "
#[Unit]
#Description=Start ClusterODM Service
#
#[Service]
#Type=simple
#PIDFile=/run/clusterodm.pid
#User=odm
#Group=odm
#WorkingDirectory=/clusterodm
#ExecStart=/usr/bin/node index.js -p 3001 --odm_path /code
#ExecStop=/bin/kill -s QUIT $MAINPID
#Restart=always
#
#[Install]
#WantedBy=multi-user.target
#
#" > /clusterodm/clusterodm.service
  
  
  ## dep and micmac
#  python -m  pip install --user utm
#  
#  cd /staging/LAStools/LASzip
#  mkdir build
#  cd build
#  cmake -DCMAKE_BUILD_TYPE=Release ..
#  make -j$CPUS
  ## potreeeconvertor
#  cd /staging/PotreeConverter
#  mkdir build
#  cd build
#  cmake -DCMAKE_BUILD_TYPE=Release -DLASZIP_INCLUDE_DIRS=/staging/LAStools/LASzip/dll -DLASZIP_LIBRARY=/staging/LAStools/LASzip/build/src/liblaszip.a ..
#  make -j$CPUS && sudo make install
#  cd /micmac
#  npm install
  #compile micmac
#  cd /home/drnmppr-micmac
#  mkdir build
#  cd build
#  cmake -DBUILD_POISSON=ON ../
#  make install -j$CPUS
  
 
  ##Expand file system to get entire disk at boot
  sudo cp ~/macodm/resizefs_local_premount /etc/initramfs-tools/scripts/local-premount/resizefs
  sudo cp ~/macodm/resizefs_hooks /etc/initramfs-tools/hooks/resizefs
  sudo chmod 755 /etc/initramfs-tools/scripts/local-premount/resizefs
  sudo chmod 755 /etc/initramfs-tools/hooks/resizefs
  sudo update-initramfs -u
  

  #MICMAC docker
#  cd ~
#  curl -fsSL https://get.docker.com -o get-docker.sh
#  sudo sh get-docker.sh
#  sudo usermod -aG docker $(whoami)
#  sudo curl -L "https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#  sudo chmod +x /usr/local/bin/docker-compose
#  sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
  #sudo docker run -d -p 3002:3000 dronemapper/node-micmac
  #sudo sed -i '12a docker run -d -p 3002:3000 dronemapper/node-micmac' /etc/rc.local
 
  echo vm.overcommit_memory = 1 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p 
  # Link services
  sudo systemctl enable /www/services/nodeodm.service
#  sudo systemctl enable /clusterodm/clusterodm.service
#  sudo systemctl enable /micmac/micmac.service
  
  sudo service nodeodm start
#  sudo service clusterodm start
  #sudo service micmac start
#  sudo sed -i '$i'"$(echo '/webodm/webodm.sh --port 80 --detached --default-nodes 0 start')" /etc/rc.local
  # clena
  sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
  sudo rm -rf /code/SuperBuild/build/opencv /code/SuperBuild/download /code/SuperBuild/src/ceres /code/SuperBuild/src/mvstexturing /code/SuperBuild/src/opencv /code/SuperBuild/src/opengv /code/SuperBuild/src/pcl /code/SuperBuild/src/pdal
  
  sudo reboot
exit 0
