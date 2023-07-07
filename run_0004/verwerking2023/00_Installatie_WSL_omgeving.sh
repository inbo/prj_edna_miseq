#!/bin/bash

# >>> init environment

sudo apt-get update -y
sudo apt-get install -y vim wget gcc zlib1g-dev make git dos2unix gzip vsearch
sudo apt-get -y install build-essential
sudo apt install python3.10-venv
sudo apt-get install python3-dev

#obitools3  en cutadapt
python3 -m venv obi3-env
 . obi3-env/bin/activate
obi3-env/bin/pip install cython
pip install obitools3
pip install cutadapt


#flash
wget https://downloads.sourceforge.net/project/flashpage/FLASH-1.2.11.tar.gz
tar -xzf FLASH-1.2.11.tar.gz
cd FLASH-1.2.11
make
sudo cp flash /usr/local/bin/
cd ..
rm -rf FLASH-1.2.11
rm FLASH-1.2.11.tar.gz

#sabre
 git clone https://github.com/najoshi/sabre.git
cd sabre
make
sudo cp sabre /usr/local/bin/
cd ..
rm -rf sabre

#paths en zo
PATH="/app/obitools3/bin:${PATH}"
echo 'export PATH="$PATH:/app/obitools3/bin"' >> ~/.bashrc
echo "source /app/obitools3/obi_completion_script.bash" >> ~/.bashrc

#paden 
mkdir run004
cd run004
mkdir run1
mkdir run2
mkdir run3
cd ..

