FROM centos:7

#install packages
RUN yum clean all; \
    rpm --rebuilddb; \
    yum install -y curl centos-release-gluster && \
    yum install -y glusterfs-server glusterfs-fuse glusterfs-api iproute

ADD initGluster.sh /usr/local/bin/initGluster.sh

ENTRYPOINT ["/sbin/init"]

