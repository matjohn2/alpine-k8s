git clone https://github.com/matjohn2/alpine-k8s.git
cd alpine-k8s/
mkdir -p /opt/cni/bin /usr/local/bin
cp -v alpine-standalone-bin/opt/cni/bin/* /opt/cni/bin/.
cp -v alpine-standalone-bin/usr/local/bin/* /usr/local/bin/.
apk update
apk add ebtables ethtool socat iproute2
# Need a running kubelet next for kubeadm to do anything useful.
# Containerized and bound to real host directories is easiest (we have no init).
apk add openrc
openrc
touch /run/openrc/softlevel
export KUBERNETES_VERSION=v1.5.4
chmod +x alpine-standalone-bin/26kubernetes.sh
alpine-standalone-bin/26kubernetes.sh
/etc/init.d/kubelet_bind_mount start
/etc/init.d/kubelet start
