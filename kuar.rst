===============================
Kubernetes Up and running notes:
================================

Lessons learned:
================

* .dockerignore: same function as .gitignore

URLs:
=====

https://github.com/kubernetes-up-and-running
  Parent directory for 6 repositories used in the book.

https://github.com/dkoleary/kuarb_docs
  Personal repo for book notes.

https://phoenixnap.com/kb/how-to-install-kubernetes-on-centos
  Kubernetes installation process on centos 7

https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
  Deploying the webui for kubernetes.  
Commands:
=========

docker image prune -a -f 
  Removes all unused images; doesn't ask for confirmation

docker build -t ${name} .
  Builds an image from the Dockerfile named/tgged w/var *-t*

docker run --rm ...
  --rm arg automatically removes the container when it exits...
  no having to run a second command.

docker system prun:
  General cleanup; removes stopped containers, dangling images, etc

eksctl create --name ${name}
  Creates an eks cluster (amazon) 

aws eks --region us-east-2 update-kubeconfig --name kuar-cluster
  Displays the kubeconfig file for an eks cluster

kubectl get svc
  Displays generic info about the cluster::

    $ kubectl get svc
    NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    kubernetes   ClusterIP   10.100.0.1   <none>        443/TCP   19m

kubectl get nodes
  Dislays worker node status

kubectl describe nodes ${node_name}
  Displays detailed information about the node.  

kubectl get daemonsets --namespace=kube-system kube-proxy 
  Displays proxy status.

Questions:
==========

* How to remove files from lower layers?  Somehow have to 'delayer' 
  or flatten the image...

Notes:
======

Chapter 1:
----------

Mainly an overview of why kubernetes and containers are so great.

Reasons:

* Velocity: Stressed:

  * Immutability of the containers
  * Declarative configurations (vs imperative - ansible vs scripts)
  * Self healing aspects

* Scaling both of software and teams
* Abstracting infrastructure:  Allows for smaller number of admins/developers
  to manage/work in larger number of systems, projects, etc.
* Efficiency

Chapter 2:
----------

* Starts by building a nodejs app.  To support this, I:

  * added personal repo
  * cloned book repo from github

* Process worked fairly well.  node is a fairly beefy immage - 912 megs.
  The incredibly small app I added on top if it added 3megs.  Talk about
  bloat

* WORKDIR, in the Dockerfile, specifies the working directory 
  **in the container**.  Basically, a container versio of ``cd``.
  Everything following is relative to that dir.

* As I observed myself, images can get large.  Book stresses that files
  removed in later layers are still present in the image.  So, how to 
  remove files from lower layers?

* Any change to a lower layer will cause all higher layers to recompile.
  Therefore, care should be taken to when applying laters:  From least 
  likely to change to most likely to change

* Secrets and images should never be mixed.  

* Ended up cheating on the golang-bad... too many issues that I'm not familiar
  enough w/the language or process to troubleshoot.  Even in containers, 
  you have to be somewhat familiar with whatever it is you're trying to build.
  I think the main point that the book is trying to make is abundanty clear 
  for multi-stage builds::

    $ docker images | head -3
    REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
    kuard               latest              88516675e747        21 seconds ago      22.9MB
    golang-bad          latest              6ad82b19a3ce        7 minutes ago       639MB

* Using repositories:  Very git-like.

  * Commands as depicted in the book don't work if you type them exactly.
  * For what should be obvious reasons, I don't have access to 
    dockerhub/kuar-demo... kuar-demo is the user name and some one else
    owns that.
  * Format for the remote repo = ${repository}/${user}/${image}:${tag}
  * The commands that eventually worked::

      $ docker tag kuard dougoleary/kuard-amd64:blue
      $ docker push dougoleary/kuard-amd64:blue

Chapter 3:
----------

Book uses cloud based kubernetes cluster which, ok... will work for learning how to
interact with the cluster; however, I was also looking for detials on installing 
one.  I think I found a cluster and will be trying it out on AWS at some point.  

I'll keep usinng the AWS cluster - just have to remember to delete it.  $0.10/hour,
$2,40/day, $36/month.  not bad, not great for doing this on the cheap.

I did kick off the commmand to create a cluster.  This takes a fair bit of time.
If this is going to take this long through the cloud, I hesitate to think what 
it'll be like on a couple of vms.

interesting.  the create command took *a long* time to finish.  When it did, 
no kubeconfig was presented.  In ordert to manage the cluster, I need to 
export KUBECONFIG=~/.kube/config

That file gets created by an aws command - also not discussed in the book.

So, the complete process is::

  eksctl create --name ${name}
  aws eks --region us-east-2 update-kubeconfig --name kuar-cluster

aws command dumps the config to stdout which can then be copied or redirected
to the config file.

Cluster components:

* kubernetes proxy: responsible for routing internal traffic between nodes.  
  must be running on all nodes of a cluster::

    $ kubectl get daemonsets --namespace=kube-system kube-proxy
    NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
    kube-proxy   2         2         2       2            2           <none>          31m

  Default name for the proxy api is daemonsets. (Book uses cap S); however,
  that can be changed.

* kubernetes DNS: handles naming and service discovery.  Book says the name
  is core-dns.  EKS has it as coredns (no dash)::

    $ kubectl get deployments --namespace=kube-system  coredns
    NAME      READY   UP-TO-DATE   AVAILABLE   AGE
    coredns   2/2     2            2           37m

* kubernetes UI:  apparently, there's a dashboard... but, it's not installed
  on eks by default.  Execute::

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml


To-dos:
=======

* Figure out docker credential store: 
  https://docs.docker.com/engine/reference/commandline/login/#credentials-store

* Figure out how to get the webui thingie working.
