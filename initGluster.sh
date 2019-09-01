#!/bin/bash


LOG=/var/log/gluster.log
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
        echo "waiting g1 glusterd online" | tee -a ${LOG}
    done
    gluster peer probe g1 ||  echo "probe g1 failed"  

    while [[ $(>/dev/tcp/g1/${GLUSTERD_PORT} 2>/dev/null || echo true) ]]; do
        sleep 0.5
        echo "waiting g1 glusterd online"
    done
    gluster peer probe g2 || echo "probe g1 failed"  

    gluster pool list  | tee -a ${LOG}

    sleep 1 &&  gluster volume create gv0 replica 2 arbiter 1 g{1,2}:/data/brick arbiter:/data/brick force  | tee -a ${LOG}
    gluster volume start gv0  | tee -a ${LOG}
}

function mountGlusterVol() {
    MOUNT_POINT=/data/glusterfs
    mkdir -p /data/glusterfs
    while [[ $(>/dev/tcp/g1/${GLUSTERFSD_PORT} 2>/dev/null || echo true) ]]; do
        sleep 0.5
        echo "waiting g1 glusterfsd online"  | tee -a ${LOG}
    done
    mount -t glusterfs -o backupvolfile-server=g2 g1:/gv0 ${MOUNT_POINT}
    echo "hello glusterfs" >>${MOUNT_POINT}/wxdlong.txt  | tee -a ${LOG}
    tail -f /dev/null
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
    docker exec -itd g1 /usr/local/bin/initGluster.sh
    docker exec -itd g2 /usr/local/bin/initGluster.sh
    docker exec -itd arbiter /usr/local/bin/initGluster.sh

    mountGlusterVol
    ;;
*)
    echo "Who am I"
    ;;
esac
}

init