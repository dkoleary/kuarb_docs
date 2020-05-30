==============================================
Notes on creating kubernetes cluster using el7
==============================================
:Title:        Kubernetes on el7
:Author:       Douglas O'Leary <dkoleary@olearycomputers.com>
:Description:  Notes o creating kubernetes clusteers on el7
:Date created: 05/25/20
:Date updated:
:Disclaimer:   Standard: Use the information that follows at your own risk.  If you screw up a system, don't blame it on me...

Goal:
=====

Ability to create a full blown, functional kubernetes clusetr on el7
preferably through the use of an ansible playbook

Notes:
======

05/25/20:

I read through the url for installing kubernetes on centos7.  Seems
reasonably straight forward.  

I also went through and verified all the older aws stuff and even created/
terminated a quick instance.  Good deal

The next effort will be to create 4 nodes - 1 master, 3 workers, and
run through the installation directions.  

05/26/20:

I created four t2.micro instances.  Going to walk through the process now.

Had a minor wrestling match w/my laptop to get pssh & pscp installed/running.

Well, I knew that was too good to be true.  Ran through the install; pacakges
installed fine.  Executing kubelet on any of the hosts results in failure.
Still looking for the reason. 

/var/log/messages::

  May 26 19:15:32 ip-172-31-21-183 kubelet: F0526 19:15:32.150901    1521 server.go:199] failed to load Kubelet config file /var/lib/kubelet/config.yaml, error failed to read kubelet config file "/var/lib/kubelet/config.yaml", error: open /var/lib/kubelet/config.yaml: no such file or directory

A bug report on github with this error was answered by saying this is the way
it's supposed to work.  ``kubeadm init`` or join and it should work.

Apparently, I have to install docker too... along with a few other config 
changes::

  # kubeadm init
  W0526 19:35:41.227092   12869 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
  [init] Using Kubernetes version: v1.18.3
  [preflight] Running pre-flight checks
  [preflight] WARNING: Couldn't create the interface used for talking to the container runtime: docker is required for container runtime: exec: "docker": executable file not found in $PATH
          [WARNING Firewalld]: firewalld is active, please ensure ports [6443 10250] are open or your cluster may not function correctly
  error execution phase preflight: [preflight] Some fatal errors occurred:
          [ERROR NumCPU]: the number of available CPUs 1 is less than the required 2
          [ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
          [ERROR FileContent--proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1
  [preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
  To see the stack trace of this error execute with --v=5 or higher

Looks like I need to go with a medium or large.  Also, the net bridge thingies 
didn't work...

// later that same day:

Trying a t2.medium - 2 cpu.  no idea how much ram it'll have though.
OK: another role generated; but have an error withe the sysctl parameter.
the host doesn't like it::

  fatal: [18.191.174.45]: FAILED! => {"changed": false, "msg": "Failed to reload sysctl: sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables: No such file or directory\n"}

I'll work on that tomorrow.  A **very** short google search shows this::

  run modprobe br_netfilter before sysctl -p will do

05/27/20:

A good portion of today has been spent getting the basic nodes set up.
Unbelievable how long I spent trying to get the br_netfilter module loaded
on boot.  Spelling's important.  who knew?

After I got that, I ran the kubeadm init - and it worked.  Several warnings
about services that weren't enabled, but it did work.  Because I'm a dumb-ass,
I didn't record the join syntax; but I did create ~dkoleary/.kube/config
as directed after which **as dkoleary** I was able to execute::

  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

It wouldn't let me do it as root. 

I'm going to terminate these instances and re-run after a bit.

Good progress.

05/29/20:

Reorganized the playbook slightly.  Re-running and then try to get a new
kubernetes cluster running.

I broke out the kubernetes creation from the aws instance creation.
I think I'm close to identifying how to add specific varialbes 
like master, worker[1-3] to separate hosts in ansible, but in the long run,
that's wasted effort.  When I move this to work, those host inventories
are going to be generated completely differently.  

05/30/20:

Not nedarly as much studying yesterday as I was hoping - in fact, none.
Regenerating the instnaces, then I'm going to work through the
kubenetes play.

kubernetes play seeming to hang on the rpm installation.  OK; that too way too
long.  

Verifying steps:

* pkgs: done
* services: done w/caveats.  kubelet says activating, like it's not quite 
  working
* set up firewalls on hosts
* verified bridge settings, etc.

Running ``kubeadm init``.  Output captured at the bottom of this doc.
Important line is::

  Your Kubernetes control-plane has initialized successfully!

Copied admin.conf to ~dkoleary/.kube/config

join command::

  kubeadm join 172.31.33.126:6443 --token syyg8c.nn43t4mjy7a6h3vy \
  --discovery-token-ca-cert-hash \
  sha256:f7a10025800a24a553feda2edb48316f7b3456d2744ca666c263be9811d7de17

**As dkoleary**, 

::

  $ kubectl apply -f \
  https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  The connection to the server localhost:8080 was refused - did you specify the right host or port?

Troubleshooting that next..  

* simple restart of kubelet didn't do it; although, it's showing active now.
* Trick was export KUBECONFIG

I did not run the kubeinit in the page because I had to do that before the 
network was set.  

So, I was expecting a bunch of problems.  The kubeadm join command specifies
a port.  When I looked on master for that port, nothing was there.  What
I didn't see::

  $ kubectl get pods --all-namespaces
  NAMESPACE     NAME                                                                  READY   STATUS    RESTARTS   AGE
  kube-system   coredns-66bff467f8-2w4vq                                              0/1     Pending   0          60m
  kube-system   coredns-66bff467f8-qmzd4                                              0/1     Pending   0          60m
  kube-system   etcd-ip-172-31-33-126.us-east-2.compute.internal                      1/1     Running   0          60m
  kube-system   kube-apiserver-ip-172-31-33-126.us-east-2.compute.internal            1/1     Running   0          60m
  kube-system   kube-controller-manager-ip-172-31-33-126.us-east-2.compute.internal   1/1     Running   0          60m
  kube-system   kube-flannel-ds-amd64-ftfq5                                           0/1     Evicted   0          23s
  kube-system   kube-proxy-pxzg2                                                      1/1     Running   0          60m
  kube-system   kube-scheduler-ip-172-31-33-126.us-east-2.compute.internal            1/1     Running   0          60m
  
Several of those lines say pending.  When I run that same commmand 
several minutes later::

  $  kubectl get pods --all-namespaces
  NAMESPACE     NAME                                                                  READY   STATUS    RESTARTS   AGE
  kube-system   coredns-66bff467f8-2w4vq                                              0/1     Pending   0          75m
  kube-system   coredns-66bff467f8-qmzd4                                              0/1     Pending   0          75m
  kube-system   etcd-ip-172-31-33-126.us-east-2.compute.internal                      1/1     Running   0          75m
  kube-system   kube-apiserver-ip-172-31-33-126.us-east-2.compute.internal            1/1     Running   0          75m
  kube-system   kube-controller-manager-ip-172-31-33-126.us-east-2.compute.internal   1/1     Running   0          75m
  kube-system   kube-flannel-ds-amd64-tg6fg                                           0/1     Evicted   0          27s
  kube-system   kube-proxy-pxzg2                                                      1/1     Running   0          75m
  kube-system   kube-scheduler-ip-172-31-33-126.us-east-2.compute.internal            1/1     Running   0          75m
  
All of them say running and there's something listening on port 6443

Running join command on worker1::

  #  kubeadm join 172.31.33.126:6443 --token syyg8c.nn43t4mjy7a6h3vy \
  >   --discovery-token-ca-cert-hash \
  >   sha256:f7a10025800a24a553feda2edb48316f7b3456d2744ca666c263be9811d7de17
  W0530 17:54:58.340055   21417 join.go:346] [preflight] WARNING: JoinControlPane.controlPlane settings will be ignored when control-plane flag is not set.
  [preflight] Running pre-flight checks
          [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
  [preflight] Reading configuration from the cluster...
  [preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -oyaml'
  [kubelet-start] Downloading configuration for the kubelet from the "kubelet-config-1.18" ConfigMap in the kube-system namespace
  [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
  [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
  [kubelet-start] Starting the kubelet
  [kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...
  
  This node has joined the cluster:
  * Certificate signing request was sent to apiserver and a response was received.
  * The Kubelet was informed of the new secure connection details.
  
  Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

and the remaining workers as well.

So, to review the process:

1.  Install aws systems, ID master and workers.
2.  Configure hosts, install kubeadm, set firewalls, etc.
2.  Run ``kubeadm init`` on master as root.

    a.  record kubeadm join command
    b.  Copy admin.config to ~dkoleary/.kube/config
    c.  su - dkoleary 
    d.  Execute pod network commmand.  Wait for it to finish loading all the 
        pods
    e.  On each worker node, execute join command.

Next, I need to verify the process again, maybe an attempt or two at automating
it, then figure out what I'm supposed to do with this wonderful new thing I've
built.

Process verification proceeding.  One of the pods is showing evicted...::

  $ kubectl get pods --namespace kube-system
  NAME                                                                  READY   STATUS    RESTARTS   AGE
  coredns-66bff467f8-bpz5f                                              0/1     Pending   0          4m30s
  coredns-66bff467f8-w89mq                                              0/1     Pending   0          4m30s
  etcd-ip-172-31-40-177.us-east-2.compute.internal                      1/1     Running   0          4m37s
  kube-apiserver-ip-172-31-40-177.us-east-2.compute.internal            1/1     Running   0          4m37s
  kube-controller-manager-ip-172-31-40-177.us-east-2.compute.internal   1/1     Running   0          4m36s
  kube-flannel-ds-amd64-88fhj                                           0/1     Evicted   0          3s
  kube-proxy-74rb6                                                      1/1     Running   0          4m30s
  kube-scheduler-ip-172-31-40-177.us-east-2.compute.internal            1/1     Running   0          4m36s
  
I'm betting it's not supposed to have that.

Waiting for port 6443 to show up - it's taking a long fucking time.  16 mintues
so far

Looks like I ran into a bug.  the core-dns pods aren't getting into running 
state after 26 m. This link talks about a bug in the network pod I'm usinng::

  https://github.com/kubernetes/kubeadm/issues/1939

This error message in /var/log/messages also seen::

  May 30 20:20:56 ip-172-31-40-177 kubelet: W0530 20:20:56.310896   11186 cni.go:237] Unable to update cni config: no networks found in /etc/cni/net.d
  May 30 20:21:00 ip-172-31-40-177 kubelet: E0530 20:21:00.060978   11186 kubelet.go:2187] Container runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized
  May 30 20:21:01 ip-172-31-40-177 kubelet: W0530 20:21:01.311140   11186 cni.go:237] Unable to update cni config: no networks found in /etc/cni/net.d

I'm going to call it a day, I think.  Some decent progress and a *mostly* 
verified process.

Lessons learned:
================

* Firewall ports:

  * master:

    * 6443/tcp
    * 2379-2380/tcp
    * 10250-10252/tcp
    * 10255/tcp

  * worker nodes:

    * 10251/tcp
    * 10255/tcp

* Admin kubeconfig located at /etc/kubernetes/admin.conf?

* Issue::

    The connection to the server localhost:8080 was refused - 
    did you specify the right host or port?

  Fix::

    export KUBECONFIG=${HOME}/.kube/config

  One would imaging that the requirement for a properly formatted config 
  file is obvious.

* Ansible firewalld module doesn't reload the firewall.  need another 
  command to do that.

URLs:
=====

https://phoenixnap.com/kb/how-to-install-kubernetes-on-centos
  Kubernetes installation process on centos 7

https://kubernetes.io/docs/concepts
  Kubernetes concepts - TOC looks alot like the book I just finished reading.

Commands:
=========

Command output:
===============

kubeadm init:
-------------

::

  # kubeadm init 
  W0530 16:36:22.893370   10246 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
  [init] Using Kubernetes version: v1.18.3
  [preflight] Running pre-flight checks
          [WARNING Firewalld]: firewalld is active, please ensure ports [6443 10250] are open or your cluster may not function correctly
          [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
  [preflight] Pulling images required for setting up a Kubernetes cluster
  [preflight] This might take a minute or two, depending on the speed of your internet connection
  [preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
  [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
  [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
  [kubelet-start] Starting the kubelet
  [certs] Using certificateDir folder "/etc/kubernetes/pki"
  [certs] Generating "ca" certificate and key
  [certs] Generating "apiserver" certificate and key
  [certs] apiserver serving cert is signed for DNS names [ip-172-31-33-126.us-east-2.compute.internal kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 172.31.33.126]
  [certs] Generating "apiserver-kubelet-client" certificate and key
  [certs] Generating "front-proxy-ca" certificate and key
  [certs] Generating "front-proxy-client" certificate and key
  [certs] Generating "etcd/ca" certificate and key
  [certs] Generating "etcd/server" certificate and key
  [certs] etcd/server serving cert is signed for DNS names [ip-172-31-33-126.us-east-2.compute.internal localhost] and IPs [172.31.33.126 127.0.0.1 ::1]
  [certs] Generating "etcd/peer" certificate and key
  [certs] etcd/peer serving cert is signed for DNS names [ip-172-31-33-126.us-east-2.compute.internal localhost] and IPs [172.31.33.126 127.0.0.1 ::1]
  [certs] Generating "etcd/healthcheck-client" certificate and key
  [certs] Generating "apiserver-etcd-client" certificate and key
  [certs] Generating "sa" key and public key
  [kubeconfig] Using kubeconfig folder "/etc/kubernetes"
  [kubeconfig] Writing "admin.conf" kubeconfig file
  [kubeconfig] Writing "kubelet.conf" kubeconfig file
  [kubeconfig] Writing "controller-manager.conf" kubeconfig file
  [kubeconfig] Writing "scheduler.conf" kubeconfig file
  [control-plane] Using manifest folder "/etc/kubernetes/manifests"
  [control-plane] Creating static Pod manifest for "kube-apiserver"
  [control-plane] Creating static Pod manifest for "kube-controller-manager"
  W0530 16:36:54.602385   10246 manifests.go:225] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
  [control-plane] Creating static Pod manifest for "kube-scheduler"
  W0530 16:36:54.603531   10246 manifests.go:225] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
  [etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
  [wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
  [apiclient] All control plane components are healthy after 16.003085 seconds
  [upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
  [kubelet] Creating a ConfigMap "kubelet-config-1.18" in namespace kube-system with the configuration for the kubelets in the cluster
  [upload-certs] Skipping phase. Please see --upload-certs
  [mark-control-plane] Marking the node ip-172-31-33-126.us-east-2.compute.internal as control-plane by adding the label "node-role.kubernetes.io/master=''"
  [mark-control-plane] Marking the node ip-172-31-33-126.us-east-2.compute.internal as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
  [bootstrap-token] Using token: syyg8c.nn43t4mjy7a6h3vy
  [bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
  [bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
  [bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
  [bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
  [bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
  [bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
  [kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
  [addons] Applied essential addon: CoreDNS
  [addons] Applied essential addon: kube-proxy
  
  Your Kubernetes control-plane has initialized successfully!
  
  To start using your cluster, you need to run the following as a regular user:
  
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
  
  You should now deploy a pod network to the cluster.
  Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
    https://kubernetes.io/docs/concepts/cluster-administration/addons/
  
  Then you can join any number of worker nodes by running the following on each as root:
  
  kubeadm join 172.31.33.126:6443 --token syyg8c.nn43t4mjy7a6h3vy \
      --discovery-token-ca-cert-hash sha256:f7a10025800a24a553feda2edb48316f7b3456d2744ca666c263be9811d7de17 
  
