#!/bin/sh -eux
# install java se 17 development kit by oracle.

# install java se 17 development kit. --------------------------------------------------------------
jdk_home="jdk17"
jdk_build="17.0.1"
jdk_folder="jdk-${jdk_build}"
jdk_binary="${jdk_folder}_linux-x64_bin.tar.gz"
jdk_sha256="6f25bcb94d3e22fb52a4632c74e03b403834e81b68701ab7ecd900fb9cd89f43"

# create java home parent folder.
mkdir -p /usr/local/java
cd /usr/local/java

# download jdk 17 binary from oracle otn.
wget --no-verbose https://download.oracle.com/java/${jdk_build:0:2}/archive/${jdk_binary}

# verify the downloaded binary.
echo "${jdk_sha256} ${jdk_binary}" | sha256sum --check
# ${jdk_folder}_linux-x64_bin.tar.gz: OK

# extract jdk 17 binary and create softlink to 'jdk17'.
rm -f ${jdk_home}
rm -rf ${jdk_folder}
tar -zxvf ${jdk_binary} --no-same-owner --no-overwrite-dir
chown -R root:root ./${jdk_folder}
ln -s ${jdk_folder} ${jdk_home}
rm -f ${jdk_binary}

# set jdk 17 home environment variables.
JAVA_HOME=/usr/local/java/${jdk_home}
export JAVA_HOME
PATH=${JAVA_HOME}/bin:$PATH
export PATH

# verify installation.
java --version
