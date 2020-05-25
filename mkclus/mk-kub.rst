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

05/25/20

I read through the url for installing kubernetes on centos7.  Seems
reasonably straight forward.  

I also went through and verified all the older aws stuff and even created/
terminated a quick instance.  Good deal

The next effort will be to create 4 nodes - 1 master, 3 workers, and
run through the installation directions.  

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


