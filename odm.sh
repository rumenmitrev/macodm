#!/bin/bash

  ## ensure 15-20G HDD

CPUS=$(grep -c ^processor /proc/cpuinfo)

sudo curl --silent --location https://deb.nodesource.com/setup_10.x | sudo bash -
sudo apt install python-gdal
sudo apt install -y nodejs

sudo apt update
sudo apt upgrade

sudo apt install -y curl python-setuptools build-essential gcc g++ cmake binutils \
  git swapspace htop libboost-dev libboost-program-options-dev exiftool python3-shapely \
  exiv2 imagemagick xmlstarlet libjpeg-progs python3-pip zip libpng-dev \
  libfreetype6-dev pkg-config qt5-default qttools5-dev-tools

# colne all needed repos
cd /
sudo git clone https://github.com/OpenDroneMap/WebODM --config core.autocrlf=input --depth 1 webodm
sudo git clone --depth 1 https://github.com/OpenDroneMap/OpenDroneMap.git code
sudo git clone --depth 1 https://github.com/OpenDroneMap/node-OpenDroneMap.git www
sudo git clone https://github.com/OpenDroneMap/ClusterODM clusterodm
#sudo git clone https://github.com/dronemapper-io/NodeMICMAC.git micmac
sudo git clone https://github.com/rumenmitrev/NodeMICMAC.git micmac

#micmac dep
sudo mkdir /staging
sudo mkdir /home/drnmppr-micmac
sudo git clone https://github.com/micmacIGN/micmac.git /home/drnmppr-micmac
sudo git clone https://github.com/pierotofy/LAStools /staging/LAStools
sudo git clone https://github.com/pierotofy/PotreeConverter /staging/PotreeConverter
sudo chown $(whoami) -R /www /code /clusterodm /staging /micmac /home/drnmppr-micmac /webodm

#ODM install
cd /code
sudo bash ./configure.sh install

# some dependencies
#echo "export PATH="$HOME/.local/bin:$PATH"" >> $HOME/.bashrc
#pip install scikit-image --use-feature=2020-resolver
#pip install utm --use-feature=2020-resolver
#python -m  pip install --user utm
#python -m  pip install --user appsettings


# Links to entwine and pdal
sudo ln -s /code/SuperBuild/install/bin/entwine /usr/bin/entwine
sudo ln -s /code/SuperBuild/install/lib/libpdal_util.so.12 /usr/lib/libpdal_util.so.12
sudo ln -s /code/SuperBuild/install/lib/libentwine.so.2 /usr/lib/libentwine.so.2
sudo ln -s /code/SuperBuild/install/lib/libpdal_base.so.12 /usr/lib/libpdal_base.so.12
sudo ln -s /code/SuperBuild/install/bin/pdal /usr/bin/pdal	

# NodeODM install
cd /www
npm install

#clusterodm install
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

# LASZip install
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

#nodeMicMac install
cd /micmac
npm install

#compile micmac
cd /home/drnmppr-micmac
mkdir build
cd build
cmake -DBUILD_POISSON=ON -DWITH_QT5=1 -DWITH_CPP11=1 ../
make install -j$CPUS

##Expand file system to get entire disk at boot
sudo cp ~/macodm/resizefs_local_premount /etc/initramfs-tools/scripts/local-premount/resizefs
sudo cp ~/macodm/resizefs_hooks /etc/initramfs-tools/hooks/resizefs
sudo chmod 755 /etc/initramfs-tools/scripts/local-premount/resizefs
sudo chmod 755 /etc/initramfs-tools/hooks/resizefs
sudo update-initramfs -u

#docker & docker compose install
cd ~
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $(whoami)
sudo curl -L "https://github.com/docker/compose/releases/download/1.28.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "
[Unit]
Description=Start webodm Service
[Service]
Type=oneshot
PIDFile=/run/webodm.pid
User=odm
Group=odm
WorkingDirectory=/webodm
ExecStart=/webodm/webodm.sh --port 80 --detached --default-nodes 0 start
ExecStop=/webodm/webodm.sh --port 80 --detached --default-nodes 0 stop
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
" > /webodm/webodm.service

# use all the swap no matter what
echo vm.overcommit_memory = 1 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p 

# Link services
sudo systemctl enable /www/services/nodeodm.service
sudo systemctl enable /clusterodm/clusterodm.service
sudo systemctl enable /micmac/micmac.service
sudo systemctl enable  /webodm/webodm.service

#sudo service nodeodm start
#sudo service clusterodm start
#sudo service micmac start
#sudo service webodm start

# clean

#sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
#sudo rm -rf /code/SuperBuild/build/opencv /code/SuperBuild/download \
#  /code/SuperBuild/src/ceres /code/SuperBuild/src/mvstexturing \
#  /code/SuperBuild/src/opencv /code/SuperBuild/src/opengv \
#  /code/SuperBuild/src/pcl /code/SuperBuild/src/pdal


# gdal compile
sudo apt-get remove gdal-bin
cd ~
wget http://download.osgeo.org/gdal/gdal-3.0.4.tar.gz
tar xvfz gdal-3.0.4.tar.gz
cd gdal-3.0.4
./configure --with-python --with-proj
make
sudo make install

echo "export PROJ_LIB=$HOME/.local/lib/python2.7/site-packages/pyproj/proj_dir/share/proj/" >> $HOME/.bashrc
#                      "/usr/local/lib/python3.6/dist-packages/pyproj/proj_dir/share/proj/"
sudo reboot
exit 0
