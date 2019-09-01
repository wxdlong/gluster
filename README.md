

查看glusterd服务状态
```bash
[root@g2 /]# systemctl status glusterd
● glusterd.service - GlusterFS, a clustered file-system server
   Loaded: loaded (/usr/lib/systemd/system/glusterd.service; disabled; vendor preset: disabled)
   Active: active (running) since Sat 2019-08-31 11:50:18 UTC; 11min ago
     Docs: man:glusterd(8)
  Process: 711 ExecStart=/usr/sbin/glusterd -p /var/run/glusterd.pid --log-level $LOG_LEVEL $GLUSTERD_OPTIONS (code=exited, status=0/SUCCESS)
 Main PID: 712 (glusterd)
   CGroup: /docker/b2c2a54479fc85ca389cd1747c108c9e9ca811da53ac1d5e675f6fb9426e6f74/system.slice/glusterd.service
           └─712 /usr/sbin/glusterd -p /var/run/glusterd.pid --log-level INFO
           ‣ 712 /usr/sbin/glusterd -p /var/run/glusterd.pid --log-level INFO

Aug 31 11:50:18 g2 systemd[1]: Starting GlusterFS, a clustered file-system server...
Aug 31 11:50:18 g2 systemd[1]: Started GlusterFS, a clustered file-system server.
```

glusterd服务监听的端口`24007`
```bash
[root@g2 /]# ss -ltnp | grep glusterd
LISTEN     0      128          *:24007                    *:*                   users:(("glusterd",pid=712,fd=10))
```

列出所有node节点
```bash
[root@g2 /]# gluster pool list
UUID                                    Hostname                        State
c6f7acc3-0e27-486a-9695-e374642c7f33    aribter.glusterfs_default       Connected
8e87d352-1037-4766-8000-02f4fd044d1a    g1                              Connected
7366d6ef-b9c0-4cbe-8a7b-ceb42d0cb2c1    localhost                       Connected
```


查看peer状态
```bash
[root@g2 /]# gluster peer status
Number of Peers: 2

Hostname: aribter.glusterfs_default
Uuid: c6f7acc3-0e27-486a-9695-e374642c7f33
State: Peer in Cluster (Connected)

Hostname: g1
Uuid: 8e87d352-1037-4766-8000-02f4fd044d1a
State: Peer in Cluster (Connected)
```

创建一个2+1(2个replicate + 1 aribter)的磁盘, force参数是因为磁盘创建在root分区。
```bash
[root@aribter /]# gluster volume create gv0 replica 2 arbiter 1 g{1,2}:/data/brick aribter:/data/brick force
volume create: gv0: success: please start the volume to access data
```

查看磁盘信息
```bash
[root@aribter /]# gluster volume info

Volume Name: gv0
Type: Replicate
Volume ID: d1e9b456-6c4b-4631-99b2-09d1a88604c1
Status: Created
Snapshot Count: 0
Number of Bricks: 1 x (2 + 1) = 3
Transport-type: tcp
Bricks:
Brick1: g1:/data/brick
Brick2: g2:/data/brick
Brick3: aribter:/data/brick (arbiter)
Options Reconfigured:
transport.address-family: inet
nfs.disable: on
performance.client-io-threads: off
```
启动volume
```bash
[root@aribter brick]# gluster volume start gv0
volume start: gv0: success
```

mount volume `gv0` 到 `/mnt/glusterfs`
```bash
mount -t glusterfs -o backupvolfile-server=g2 g1:/gv0 /mnt/glusterfs
```

检查是否挂载成功
```bash
[root@client glusterfs]# ps -ef | grep gluster
root       861     0  0 13:15 ?        00:00:00 /usr/sbin/glusterfs --process-name fuse --volfile-server=g1 --volfile-server=g2 --volfile-id=/gv0 /mnt/glusterfs
[root@client glusterfs]# mount | grep gluster
g1:/gv0 on /mnt/glusterfs type fuse.glusterfs (rw,relatime,user_id=0,group_id=0,default_permissions,allow_other,max_read=131072)
[root@client glusterfs]# df -h /mnt/glusterfs/
Filesystem      Size  Used Avail Use% Mounted on
g1:/gv0         126G   32G   89G  27% /mnt/glusterfs
```


>Failed to get D-Bus connection: Operation not permitted