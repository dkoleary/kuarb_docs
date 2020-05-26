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

URLs:
=====

https://phoenixnap.com/kb/how-to-install-kubernetes-on-centos
  Kubernetes installation process on centos 7

https://kubernetes.io/docs/concepts
  Kubernetes concepts - TOC looks alot like the book I just finished reading.

Commands:
=========


