set -eux

echo "Play with Docker Node IP address is:"
export LOCAL_IP_ETH1=`ifconfig eth1 | grep "inet addr" | cut -d ':' -f 2 | cut -d ' ' -f 1`
echo ${LOCAL_IP_ETH1}

echo "Pre-loading the hyperkube image gcr.io/google_containers/hyperkube:${KUBERNETES_VERSION}..."
docker pull gcr.io/google_containers/hyperkube:${KUBERNETES_VERSION}
docker pull gcr.io/google_containers/hyperkube-amd64:${KUBERNETES_VERSION}

echo "Setup shared /var/lib/kubelet bind mount service..."
cat >/etc/init.d/kubelet_bind_mount <<EOT
#!/sbin/openrc-run
# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# \$Header: \$

start_pre() {
  return 0
}

start() {
  ebegin "Creating /var/lib/kubelet shared mount"
  mkdir -p /var/lib/kubelet && \
  mount --bind /var/lib/kubelet /var/lib/kubelet && \
  mount --make-shared /var/lib/kubelet
  eend \$?
}

stop() {
   ebegin "Umounting shared bind volume /var/lib/kubelet"
   umount /var/lib/kubelet
   eend \$?
}
EOT
chmod +x /etc/init.d/kubelet_bind_mount
rc-update add kubelet_bind_mount boot

echo "Create kubelet service..."
cat >/etc/init.d/kubelet <<EOT
#!/sbin/openrc-run
# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# \$Header: \$

depend() {
  need kubelet_bind_mount
}

start_pre() {
  ulimit -n 1048576
  return 0
}

start() {
  ebegin "Starting Kubelet"
  /usr/local/bin/docker run -d --restart=on-failure --name kubelet \
       --volume=/:/rootfs:ro \
       --volume=/sys:/sys:ro \
       --volume=/var/lib/docker/:/var/lib/docker:rw \
       --volume=/var/lib/kubelet/:/var/lib/kubelet:shared \
       --volume=/etc:/etc:rw \
       --volume=/opt:/opt:rw \
       --volume=/var/run:/var/run:rw \
       --net=host --privileged=true \
       gcr.io/google_containers/hyperkube:${KUBERNETES_VERSION} \
       /hyperkube kubelet \
        --containerized \
        --address="0.0.0.0" \
        --pod-manifest-path=/etc/kubernetes/manifests \
        --allow-privileged=true \
        --v=4 \
        --hostname-override=master1.example.com \
  eend \$?
}

stop() {
   ebegin "Stopping Kubelet"
   /usr/bin/docker stop kubelet && /usr/bin/docker rm kubelet
   eend \$?
}
EOT
chmod +x /etc/init.d/kubelet

exit 0
