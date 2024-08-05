#!/bin/bash
# 
# a utility for building equivs packages, only
# used during container creation to satisfy
# apt deps we're building out ourselves (such as python)
#
mkdir -p /root/equivs
cd /root/equivs

echo "$1 install" | dpkg --set-selections

equivs-control $1_$2.control
sed -i "s/<package name; defaults to equivs-dummy>/$1/g" $1_$2.control
sed -i "s/# Version: <enter version here; defaults to 1.0>/Version: $2+x4d/g" $1_$2.control
sed -i "s/# Multi-Arch: <one of: foreign|same|allowed>/Multi-Arch: allowed/g" $1_$2.control
equivs-build --arch amd64 $1_$2.control
equivs-build --arch i386 $1_$2.control
#equivs-build $1_$2.control
dpkg -i $1_$2+x4d_amd64.deb
dpkg -i $1_$2+x4d_i386.deb
#dpkg -i $1_$2+x4d_all.deb
echo "$1 hold" | dpkg --set-selections
echo "$1:amd64 hold" | dpkg --set-selections
echo "$1:i386 hold" | dpkg --set-selections
