#!/bin/bash


BRICK=/data/brick
GLUSTERD_PORT=24007
GLUSTERFSD_PORT=49152

function startGlusterd() {
    systemctl start glusterd
    mkdir -p ${BRICK}
}

## Wating g1,g2 online. Then create volume
function initGlusterfs() {
    while [[ $(>/dev/tcp/g1/${GLUSTERD_PORT} 2>/dev/null || echo true) ]]; do
        sleep 0.5
        echo "waiting g1 glusterd online"
    done
    gluster peer probe g1 ||  echo "probe g1 failed"  

    while [[ $(>/dev/tcp/g1/${GLUSTERD_PORT} 2>/dev/null || echo true) ]]; do
        sleep 0.5
        echo "waiting g1 glusterd online"
    done
    gluster peer probe g2 || echo "probe g1 failed"  

    gluster pool list

    gluster volume create gv0 replica 2 arbiter 1 g{1,2}:/data/brick arbiter:/data/brick force
    gluster volume start gv0
}

function mountGlusterVol() {
    mkdir -p /mnt/glusterfs
    while [[ $(>/dev/tcp/g1/${GLUSTERFSD_PORT} 2>/dev/null || echo true) ]]; do
        sleep 0.5
        echo "waiting g1 glusterfsd online"
    done
    mount -t glusterfs -o backupvolfile-server=g2 g1:/gv0 /mnt/glusterfs
    echo "hello glusterfs" >>/mnt/glusterfs/wxdlong.txt
}

function init(){
case ${NODE_TYPE} in
arbiter)
    echo "I am arbiter"
    startGlusterd
    initGlusterfs
    ;;
gv)
    echo "I am $(hostname)"
    startGlusterd
    ;;
gc)
    echo "I am gluster client"
    mountGlusterVol
    ;;
*)
    echo "Who am I"
    ;;
esac
}

init

tail -f /dev/null