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

eksctl delete cluster --name kuar-cluster
  Deletes the cluster

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

Chapter 1: General overview
---------------------------

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

Chapter 2: Containers
---------------------

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

Chapter 3: Starting kubernetes
------------------------------

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

(05/17/20)


Chapter 4: General kubectl commannds
------------------------------------

Before getting into ch4, I'm working through the help for eksctl.  
Interestingly enough, it will auto-generatre the ~/.kube/config ... assuming
~/.kube exists?  Going to check on that in a bit.

Timing:

  * Started:  clustr generation at 1058 CST.
  * Initial display on aws console: ~1101 CST.
  * Console says ready at: 1115 CST.  Still waitinng on nodes to be ready

General kubectl commands:

* Namespaces: basically a folder for a set of objects.  Everything in a 
  kubernetes cluster is in a namespace.  The default name space is *default*.
  Options to modify the name space::

    kubectl --namespace ${ns}
    kubectl --all-namespaces

* Contexts:  Can be used to change the default namespace (and other things,
  I imagine) permanently.  Gets stored in the ~/.kube/config.  Optionw::

    # to create a context
    kubectl config set-context my-context --namespace=mystuff
    # to start using the context:
    kubectl config use-context my-context
    # manage different users/clusters
    kubectl config set-context ... --clusters | --users

* Viewing kubernetes objects:

  * Everything is an API; in fact, kubectl only executes http requests to 
    the approrpiate urls.  

  * kubectl get::

      kubectl get ${resourcename} # generic; lists all recourses in namespace
      kubectl get ${rn} ${ojbect} # get info on specifc object

  * kubectl describe ${rn} ${obj}:  dumps a shit load of data about the object

* Creating/updating/destroying objects:

  * All done through yaml files via ``kubectl apply -f ${yaml}``
  * kubectl has a --dry-run flag.
  * ``kubectl edit``  # downloads the yaml, allows you to edit, then uploads
    when done.
  * History of edits of objects are viewable via::

      kubectl apply -f ${yaml} view-last-applied

  * ``kubectl delete ${rn} ${obj}``

* Labels/Tags::

    kubectl [ label|annotate] ${rn} ${obj} ${key}=${value} [--overwrite]]
    kubectl [ label|annotate| ${rn} ${obj}-

* Logs::

    kubectl logs ${pod}  # display logs for single container pod
    kubectl logs ${pod} -c ${container-id}
    kubectl logs ${pod}} -t # k-version of tail -f
    
* Other commands

  * Copy files to/f container: ``kubectl cp ...``
  * Execute command in pod: ``kubectl exec -it ${pod}...``
  * Open another port in pod:  ``kubectl port-forward ${pod} 8080:80``
  * Display resources: ``kubectl top [ nodes | pods ]``

Chapter 5: Pods
---------------

* Topic of colocating multiple apps on a single worker node - which, as it
  turns out, is the definition of a pod.

  * Should have one app = 1 container which allows for resource limitation
    at the container level
  * Seems to indicate a pod runs on one and only one node.
  * And, just confirmed.  pods are the smallest deployable artifact and
    always land on one system.
  * pods share namespaces, networking, and can communicte via native
    interprocess comms channels
  * containers in different pods share nothing even if on the same host.  IOW:
    containers in different pods on the same node might as well be on different
    worker nodes.
  * To pod or not to pod: the question is "Will these two apps work correctly
    if they land on different worker nodes?"  If no, one pod, if yes, 
    different pods.
  * Once on a node, pods don't move.  How to migrate a pod?  stop/start?

* Creating a pod::

    kubectl run --image=${image}

  I didn't have to specify dockerhub.  just *dougoleary/kuard-amd64* which
  implies the cluster has a registry search configured somewhere.

  I also didn't specify a name space so.. this is in *default*?  Yep, sure
  enough::

    $ kubectl get pods --all-namespaces
    NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
    default       kuard                      1/1     Running   0          2m26s
    kube-system   aws-node-p5js8             1/1     Running   0          49m
    kube-system   aws-node-xcd5s             1/1     Running   0          48m
    kube-system   coredns-5fb4bd6df8-7jllj   1/1     Running   0          55m
    kube-system   coredns-5fb4bd6df8-gl9w6   1/1     Running   0          55m
    kube-system   kube-proxy-8m8wb           1/1     Running   0          49m
    kube-system   kube-proxy-qkc65           1/1     Running   0          48m

* Deleting pods::

    kubectl delete pods/kuard

* pod manifest:

To-dos:
=======

* Figure out docker credential store: 
  https://docs.docker.com/engine/reference/commandline/login/#credentials-store

* Figure out how to get the webui thingie working.
* Figure out how to configure registry searches.
