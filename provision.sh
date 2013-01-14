#!/usr/bin/env sh

# install HipHop's dependencies. Fucking great.

# First we get yum's prepackaged gcc (4.4 at time of writing)
# Need difftools (cmp) to do stuff
yum -y install make gcc gcc-c++.x86_64 diffutils.x86_64 m4.x86_64 wget.x86_64 ppl-devel.x86_64 cloog-ppl-devel.x86_64 elfutils-devel.x86_64 

# BEGIN prerequisites to gcc 4.7 (as of writing, SL6 package mgr only has 4.4)
cd /vagrant/gmp-5.1.0
mkdir -p /usr/local/src/gmp-5.1.0
/vagrant/gmp-5.1.0/configure
make
make install
# make check # revealed 2 errors

mkdir -p /usr/local/src/mpfr-3.1.1
/vagrant/mpfr-3.1.1/configure
make
make install

mkdir -p /usr/local/src/mpc-1.0.1
/vagrant/mpc-1.0.1/configure
make
make install

# installing zip/unzip after receiving message:
# gcc configure: error: cannot find neither zip nor jar, cannot continue

yum -y install unzip.x86_64 zip.x86_64

# END prereqs

# now we actually install gcc 4.7
mkdir -p /usr/local/src/gcc-4.7.2
cd /usr/local/src/gcc-4.7.2
/vagrant/gcc-4.7.2/configure
make
make install

mv /usr/bin/gcc /usr/bin/gcc-old
mv /usr/bin/g++ /usr/bin/g++-old
mv /usr/bin/c++ /usr/bin/c++-old
ln -s /usr/local/bin/c++ /usr/bin/c++
ln -s /usr/local/bin/gcc /usr/bin/gcc
ln -s /usr/local/bin/g++ /usr/bin/g++

yum -y install cmake boost boost-devel flex bison mysql.x86_64 mysql-devel gd gd-devel.x86_64 libicu-devel.x86_64 bzip2-devel.x86_64
yum -y install oniguruma oniguruma-devel.x86_64 git-all.noarch elfutils-libelf-devel pcre-devel.x86_64 pcre.x86_64 libxml2-devel.x86_64 expat-devel.x86_64

rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
yum -y install php53-mcrypt libmcrypt-devel.x86_64

yum -y install openldap-devel.x86_64 readline-devel.x86_64 libc-client-devel.x86_64 libcap-devel.x86_64 binutils-devel.x86_64 pam-devel.x86_64

# not available on yum
cd /vagrant/re2c-0.13.5
./configure
make
make install

# not available on yum
cd /vagrant/glog-0.3.2
./configure
make
make install

# fb has a patched version of libcurl
cd /vagrant/curl-7.28.1-patched
./configure
make
make install

# fb has a patched version of libevent
cd /vagrant/libevent-1.4.14b-stable-patched
./configure
make
make install

cd /vagrant/libunwind-1.0.1
./configure
make
make install 

# HACK: there is a copy error here when trying to copy the generated libunwind.a to libunwind-generic.a
# to get around this, we manually copy it back to the src/ directory and run make install a second time...

cp /usr/local/lib/libunwind-x86_64.a src/libunwind-x86_64.a
make install

# ENDHACK

cd /vagrant/libiconv-1.14
./configure
make
make install

# hh needs >= v0.39
cd /vagrant/libmemcached-1.0.15
./configure
make
make install

cd /vagrant/dwarf-20121130/libdwarf
./configure
make
cp libdwarf.a /usr/local/lib/libdwarf.a


# Intel Thread Building Blocks library (why the fuck not)
# cd /vagrant/tbb41_20121003oss
# gmake
# source /vagrant/tbb41_20121003oss/build/linux_intel64_gcc_cc4.4.6_libc2.12_kernel2.6.32_release/tbbvars.sh

# courtesy of https://github.com/jackywei/HOW-TO-BUILD-HHVM-WiKi/blob/master/CentOS6.3_HHVM/buildhhvm/8_tbb.sh
cd /vagrant/tbb40_20120613oss/
make > make.log

# HACK just sourcing the tbb vars doesn't work by itself, need to manually assign new vars
awk 'END {print}' make.log |sed -e 's/`/ /' -e "s/'//" |awk {'print $4'} > tmpname
TBB_NAME=`cat tmpname`
echo =========================================================================
echo TBB_LIBPATH=$TBB_NAME
echo =========================================================================
rm -f tmpname

mkdir -p /usr/include/serial
cp -a include/serial/* /usr/include/serial/
mkdir -p /usr/include/tbb
cp -a include/tbb/* /usr/include/tbb/
cp $TBB_NAME/libtbb.so.2 /usr/lib64/
ln -s -f /usr/lib64/libtbb.so.2 /usr/lib64/libtbb.so

# install HipHop HHVM
cd /usr/local/src
git clone git://github.com/facebook/hiphop-php.git
cd hiphop-php
git submodule init
git submodule update
export HPHP_HOME=`pwd`
export HPHP_LIB=`pwd`/bin
export USE_HHVM=1
cmake .
