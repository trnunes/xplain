# Xplain Exploration Environment

Xplain is the a highly expressive exploration environment that generalizes the majority of the state-of-the-art environments. We designed Xplain on the top of the most complete framework of data processing operations targeting exploration tasks.

## Demonstration Videos
* Demo 1: https://youtu.be/bG9qYv5mvU0
* Demo 2: https://youtu.be/VkzE2ONZNWA

## Docker Installation
1. You must have docker installed. Refer to https://docs.docker.com/install/
2. Pull the container: `docker pull trnunes/xplain:0.0.1`
3. `mkdir xplain`
4. Download the docker-compose.yml at https://github.com/trnunes/xplain/blob/faceted_search/docker-compose.yml
5. Move the docker-compose.yml to your xplain dir
5. `cd xplain`
6. execute: `sudo docker stack deploy -c docker-compose.yml xplain`
7. Verify your IP address with ifconfig or ipconfig
8. Access blazegraph server at http://<your_ip>:8889/bigdata
9. Access xplain at http://<your_ip>:3000


## Manual Installation
### Prerequisites
1. Java JDK and JAVA_HOME properly set
2. Jruby 9.1.13.0
3. Rails 4.2.*
3. Bundler 1.16.2

### Ubuntu Installation
You must have git installed
#### Install Java 
1. Open the terminal and type the following commands:
2. `sudo apt-get update`
3.`sudo apt-get install openjdk-8-jre`
4. Open /etc/environment in any text editor like nano or gedit and add the following line `JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"`
5. In terminal: `source /etc/environment` and `echo $JAVA_HOME` to verify if JAVA_HOME has been properly set.
#### Install Jruby and Bundler
We recomend the Jruby-9.1.13.0, which is the version we used in Xplain's development environment.

We strongly recomend installing jruby through ruby version management tool rvm. For installing the rvm, follow the steps in https://github.com/rvm/ubuntu_rvm. However, you can also download the binaries and install manually (see https://github.com/jruby/jruby/wiki/GettingStarted). 

Once Jruby is set up, open terminal and install bundler: ` jgem install bundler -v 1.16.2`
### Setting up Xplain
Execute the following steps in terminal:
1. `git clone https://github.com/trnunes/xplain.git`
2. `cd <cloned-xplain-dir>`
3. `git fetch`
4. `bundle install --local`
5. run xplain with: `jruby -S -J-Xmx4g bin/rails s`
6. access http://localhost:3000


### Windows Installation (TODO)
