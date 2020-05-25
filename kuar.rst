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

https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
  How to execute a deployment.

https://kubernetes.io/docs
  Current docs for kubernetes

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

kubectl delete pods --all --namespace=default
  Deletes all pods in a namespace.  Should probably use this somewhat
  judiciously.

Questions:
==========

* How to remove files from lower layers?  Somehow have to 'delayer' 
  or flatten the image...
* How to limit, at a cluster level, sources for persistent storage?
* (answerd) What is difference between pod and deployment?  pods are 1 or more 
  containers, deployments are 1 or more duplicate pods.  

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

Book uses cloud based kubernetes cluster which, ok... will work for learning 
how to interact with the cluster; however, I was also looking for detials on 
installing one.  I think I found a cluster and will be trying it out on AWS 
at some point.  

I'll keep usinng the AWS cluster - just have to remember to delete it.  
$0.10/hour, $2,40/day, $36/month.  not bad, not great for doing this on 
the cheap.

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

    kubectl run kuard --image=${image}

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

05/19/20:

* Starting kuar-cluster:

  * Started: 1003
  * Full command back: 1021

* pod manifest:

  * Key fields/attributes:

    * metadata section - at least the name of the pod.
    * spec section:  details the container, storge, etc.  

  * After creating the pod manifest, run it via ``kubectl apply -f ${yaml}``
    NOTE: if the image doesn't have a latest, need to specify a tag in the
    image line of the manifest.

  * Starting pods::

      kubectl run ${name} --image=${image}
      kubectl apply -f ${manifest}

  * Stopping pods::

      kubectl delete pods ${name}
      kubectl delete -f ${manifest}

    Terminated pods have a grace period of (default) 30 seconds.  IOW: pods
    don't die immediately.

  * port forwarding: creates a tunnel between local system (from which kubectl
    is being run) to the pod.  The port forwarding works like ssh in that 
    the command blocks until <ctrl-c> at which point the port is no longer 
    forwarded::

      kubectl port-forward kuard 8080:8080
      # then can curl http://localhost:8080

    Nothing in a ``kubectl describe`` command indicates that there's a 
    forwarded port.

  * logs: ``kubectl logs ${pod}``

  * Accessing pods::

      kubectl exec ${pod} ${cmd} # similar to remote ssh command
      kubectl exec -it ${pod} /bin/bash # remote login

  * Copying files via kubectl::

      # from pod:
      kubectl cp ${pod}:/${dir} ${tgt}
      # to pod:
      kubectl cp ${src} ${pod}:/${dir}/${tgt}

    And, I quote for Suresh::

      Generally speaking, copying files intoa  container is an anti-pattern.
      You really should treat the contents of a container as immutable.
      But, occasionally, it's the most immediate way to stop the bleeding 
      and restore your service to health, since it is quicker than building,
      pushing, and rolling out a new image.  Once the bleedinng is stopped,
      however, it is critically important that you immediately go and do the
      image build and rollout, or you are guaranteed to forget the local 
      change that you made to your container and overwrite it in the subsequent
      regularly scheduled rollout.

* Health checks:  

  * kubernetes runs generic health check that ensures the
    main process of the pod/container is running.  If it isn't, kubernetes
    will restart it.  
  * Doesn't tell if a process is hung or otherwise non-responsive.
  * *liveness probes*:  Logic to verify the application is doing what it's
    supposed to be doing.  Since these checks are app specific, they have to
    be defined in the manifest.

    * Example::

        [[snip]]
        spec:
          containers:
            - image: dougoleary/kuard-amd64:blue
              name: kuard
              livenessProbe:
                httpGet:
                  path: /healthy
                  port: 8080
                initialDelaySeconds: 5
                timeoutSeconds: 1
                periodSeconds: 10
                failureThreshold: 3
              ports:
              [[snip]]

    * Definition: Creates an httpGet probe which checks the /healthy end 
      point on port 8080.  It won't be called for 5 seconds (initialDelay)
      after all containers of the pod are active.  The probe must repond
      within 1 second (timeoutSeconds).  the probe will be called every 10
      seconds (periodSeconds) and, if three or more consecutive probes 
      (failureThreshold) fail, the container/pod fails/restarts.

    * interesting that I can't define that and push to a live container.
 
  * Readiness probe: very similar to liveness check; however, failure will
    result in removal from load balancer.  liveness check failures result 
    in pod restart.

* Resource management:

  * Misc:

    * Resources requested per container not per pod. 
    * Pod resources are combination of all subordinate containers.
    * Resource metrics need some investigation.  *500m* somehow translates
      to half a core.

  * Requests:  min amount of a resource required to start a pod.  
  * Limits: max amount of a resource a pod can consume.
    
* Persistent volumes: mostly discussed in chapter 15.

  * new stanzas:

    * volumes (in the spec stanza).  Defines volumes that the pod *can* mount.
    * volumeMounts in container sectoin: defines what the container mounts.

  * Volume types:

    * comms/synchornization:  emptyDir, scoped to a pod's lifecycle.  
    * cache:  valuable for performance but not required for correct operation 
      of an application.
    * Persistent data:  truly persistent data.
    * Mounting host filesystems: actually using host's filesystems.  book uses
      /dev as an example.  hostpath

05/20/20:

Chapter 6: labels and annotations
---------------------------------

Definition:

  * labels: key/value pairs that can be attached to kubernetes objects.
    They are arbitrary and are useful for attaching identifying information
    to objects
  * Annotations: key/value pairs that hold non-identifying information that
    can be leveraged by tools and libraries.

The book promises that the distinction will become clear.

Labels:
~~~~~~~

* label format:

  * Key: [ prefix ] / name

    * Prefix is optional; but, if supplied, must be a DNS subdomain.
    * Names:

      * < 63 chars long
      * start and end with alphanumeric
      * can use [ -_. ]

  * Value: a string - even if the string is a number.

* Running through the example in the book; got 4 pods running.  
  ``kubectl get deployments`` doesn't show anything though... 
  What is the difference?  (answered).  Also explains why kubectl is 
  bitching about the replicas.  Doesn't look like there's a way to run 
  a deployment outside of a yaml file.  

  * pods: defined already - one or more containers
  * deployment: maintains a set of replicated pods.

* Outside of replacing deployments with pods, examples in the book are good.

  * --show-labels
  * --L ${label} = make ${label} a column::

      $ kubectl get pods -L canary
      NAME                READY   STATUS    RESTARTS   AGE   CANARY
      alpaca-prod         1/1     Running   0          17m   
      alpaca-test         1/1     Running   0          16m   true
      bandicoot-prod      1/1     Running   0          15m   
      bandicoot-staging   1/1     Running   0          14m   

  * Remove a label: ``kubectl label pods ${name} "${label}-"`` 
  * Filtering::

      --selector="${key}=${val}"  Filters search by the labels.

    Can also use pythonic syntax::

      --selector="app in (alpaca, bandicoot)"

    Can also use pythonic syntax::

      --selector="app in (alpaca, bandicoot)"

Annotations:
~~~~~~~~~~~~

* Stores metadata about kubernetes objectss with the sole purpose
  of assisting tools and libraries.  Book describes them as 'opaque'

* Used for:

  * Keep track of a reason for the latest update to an object.
  * Communicate a schedule to a specialized scheduler
  * Extend data about what tool made the last change.
  * Attach build, release, or image info not appropriate for labels.
    Examples given: git has, timestamps, or PR number.
  * Enable deployments to keep track of the replica sets.
  * Provide extra data to enhance visual quality or usability of a UI.
  * Prototype alpha functionality in kubernetes.

* Best use case: rolling deployments.  
* Format: keys use the same format as labels, values is a free form string 
  field.  Can store things like json docs.  since it's free form, probably
  unsearchable.

Chapter 7: service discovery
----------------------------

* Problem statement: kubernetes is dynamic.  People can and do create 
  lots of things.  How to find and distinguise these 'lots of things'?

  Service discovery is the general name for the problem and solutions.

* Discussion of issues with traditional DNS.
* More kubectl with replicas.  doesn't work with ``kubecctl run``  I tried
  hacking a deployment yaml file but apparently need more info. I did finnally
  find ``kubectl create deployment``.  Unfortunately, that doesn't quite work
  either.  Still going with the pods, for now.
* Looks like that's going to be a problem.  Doesn't seem like I can expose
  a pod.. Never mind, you can::

    $ kubectl expose pods alpaca-prod --port=8080
    service/alpaca-prod exposed
    $ kubectl get services -o wide
    NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE    SELECTOR
    alpaca-prod   ClusterIP   10.100.128.242   <none>        8080/TCP   13s    app=alpaca,env=prod,ver=1
    kubernetes    ClusterIP   10.100.0.1       <none>        443/TCP    122m   <none>

  * type=NodePorts: exposing apps to the internet.  
  * type=Loadbalancer: creates a load balancer in cloud envs.
  * Manually identify services via ip assocaited with the pods, then add the
    nodeport
  * kubeproxy: 
  * May need to re-do this chapter after I go through deployments.  Aother 
    probable issue is that I don't think my kube cluster is internet 
    accessible.

Chapter 8: load balancing with ingress
--------------------------------------

High level review of a very involved topic.  I read through the chapter.
Ingress will require more research.

Chapter 9: Replica sets
-----------------------

Replica sets duplicate pods.  reasons to replicate pods:

* redundancy
* scale
* sharding - different replicas handling different parts or the computation
  in parallel

Reconciliation loop:
  The loop(s) required to bring the replica set from desired state to current
  state.

Replica sets create and manage pods, they don't own them.  replicasets and pods
have been decoupled.  Might explain why the current version of kubectl doesn't
work as the book describes.  rapidly changing development stream.

Can also add replicasets on the fly; however, book stresses that you need to 
go back to the source yaml to ensure the change is in source control.

Entertainingly, can also quarantine a pod if it's misbehaving for 
troubleshooting purposes.

Yaml presented in the book is almost certainly out of date.  Yep; according to
the docs, replicaset's apiVersion is *app/v1*.  in the book, it's
*extensions/v1beta1*.  

Pod templates:  Define the source for the pods/containers.

Stanza in the replicaset yaml file that defines selector labels, and container
information.  I'll need to experiment more with these.

Autoscaling:

  Types of autoscaling:

  * verticle: adding more resources (cpu, memory, etc) for individual pods/
    containers
  * Horizontal: Adding more pods for greater bandwidth.  Horizontal Pod
    Autoscaling (HPA)

cpu example::
  
  kubectl autoscale rs ${rep_name} --min=2 --max=5 --cpu-percent=80

Chapter 10:  Deployments
------------------------

Going to read through this chapter as well since the book seems to be out of 
date.  Rest of this study period will be spent trying to get a kubernetes 
cluster running.

Relationship:

* Deployments: contain one or more:

  * Replicasets: contains one or more:

    * pods:  contain one or more:

      * containers: 
      * services:

Relationship is defined by labels and a selector label

If manually scale a deployment's replicaset, kubernetes will revert it.
The definition is set at the deployment level, not the replicaset 
level.


Deployment spec similr to replicaset spec.  Deployments add a strategy 
object::

  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate

Strategy types:

* RollingUpdate:  more robust and user friendly; however, adds potential
  for race conditions between versions as both will be running simultaneously.

  * maxunavailable: how many pods can be out of commisison at once.  
    maxunavailable=0% = recreate strategy.
  * maxSurge: how many additional pods/resources, etc, can be created to 
    accomplish the rolling update

* Recreate:  Basically, blasts all current pods. kubernetes recreates with 
  updated image.  Easier and more straight forwawrd but some downtime.

Updating deployments:

* Scaling:  Update the yaml file to incrase/decrease replicas; kubernetes
  handles the rest.
* Updating container image: 

  * Update image line as needed.
  * Add annotation stanza in the template's metadata section

Other commands::

  kubectl rollout status deployments ${name}
  kubectl get replicasets  -o wide
  kubectl rollout pause deployments ${name}
  kubectl rollout resume deployments ${name}
  kubectl rollout history deployment ${name} --revision=${num}

Chapter 11: Daemonssets
-----------------------

Daemonsets schedule a single pod on all nodes of a kubernetes cluster.
Such pods would include:

* log collectors
* monitoring agents

If you want only one pod on a node, use a daemonset.
If the pod can run multiple copies on a the same node w/o issue, use 
replicatset.

Since it's running pods, must have a template section like deployments
and replicasets.

Can use labels and node selections to limit the nodes on which the daemonset
will run.

Chapter 12: jobs
----------------

jobs are one-off processes that run until successful.  The other services
discussed will get restarted if they terminate.  jobs are supposed to 
terminate.  Example given: db migration.  Don't want that to keep kicking off
but run once and only once.

Main items to add to the template:

* completions:  the number of jobs that need to complete?
* parallelims: the number of simultaneously running pods.

Chapter 13: configmaps and secrets
----------------------------------

Basically, kubernetes version of hiera and eyaml (puppet) or vars_files and
ansible-vault.  

Main uses for configmaps:

* filesystem mounts
* environment variables
* command line arguments

Examples in the book look very useful; however, need some way to parameterize
the config map source.  IOW, if the pod definition is hard-coded to a specific
config map, the pod definition will have to get updated for each environment.  

I think I figured it out - you don't use parameters as part of the pod 
definition - you use different namespaces each with their own configmaps and
secretts.  

Secrets: warning is scary: secrets are stored in the etcd storage in clear text.

Secrets are exposed to pods via a *secrets volume* which must be definned in 
the pod manifest.

Chapter 14: Role based access controls
--------------------------------------

RBAC introduced in v1.5 and became generally available in v1.8

Some miscellaneous data points:

* Every request to kubernetes is authenticated even if it is
  *system:unauthenticated*
* Kubernetes does not have a built in identity store; rather, it integrates
  with other identity sources.
* Authorization is a combination of the user, the resource requested, and
  the verb being used.

Types of identities:

* user identities = people, application accounts, etc.
* service identities = IDs created and managed by kubernetes generally
  associated with cluster components.

Roles and role bindings by namespace and cluster:

* roles/rolebinding

  * Roles: define actions a specifc rol can perform::

      kind: Role
      apiVersion: rbac.authorization.k8s.io/v1
      metadata:
        namespace; default
        name: pod-and-service
      rules:
      - apiGroups: [""]
        resources: ['pods', 'services']
        verbs: [ 'create', 'delete', 'get', 'list', 'patch', 'update', 'watch']

  * rolebinding: As name suggests, assigns roles to users or groups::

apiVersion: rback.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: default
  name: pods-and-services  # note name of rolebinding, not name of role
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: user
  name: alice
- apiGroup: rbac.authorization.k8s.io
  kind: group
  name: mydevs
rolref:
  apiGroup: rbac.authorization.k8s.io
  kind: role
  name: pod-and-services

* clusterrole/clusterrolebinding:  largely identical to above but give
  access to the entire cluster ranther than individual name spaces.

Thank god, there are built-in roles.  Having to define that crap on my own
was going to be f'ing ugly.

* cluster-admin: complete access to the entire cluster.
* admin: complete access to the defined namespace
* edit: allows editing in a namespace
* view: allows views in a namespace

Numerous clusterrolebindings visible via::

  kubctl get clusterrolebindings

Testing autorization: can-i::

  kubectl auth can-i create pods
  kubectl auth can-i get pods --subresource=logs

Can manage rbac through yaml then exec::

  kubectl auth reconcile -f ${yaml}.yaml [ --dry-run ]

Roles can be aggregated to groups of groups so modifications to a subgroup
will get reflected in the superset.  Not much more than a surface discussion.

Fairly involved discussion of using user groups as the access mechanism.  
no details on how to configure AD or ldap auth, though.  There was a lengthy
list of available authetnication vehicles.

Chapter 15: integrating storage solutions
-----------------------------------------

Complex apps almost always require some state.  Containers are more apt for
stateless, but support the state apps.  This state will generally be handled
via storage

Importing external services
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Example: legacy db running that can't be migrated to kubernetes.  *Importing*
this db into kb makes it look like the external db is part of the cluster.

Running reliable singletons
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Example is a mysql db in a pod and how to expose that pod to other apps in the
cluster

Needed:

* persistent volume to store the db data

  * Persistent volume definition:  managed by cluster admin?  Is that how 
    we prevent ztp from defining ad-hoc volumes?
  * persistent volume claim

* mysql pod
* service to expose the pod.

Statefulsets:
~~~~~~~~~~~~~

Apparently, the future.  Like RBAC, introduced in v1.5.  Not generally 
available?

Breezed through.  As the book is fairly dated, I imagine this topic has
moved a bit.  I'll research more later.

Summary:
========

Good book, particularly in the first few chapters.  Later chapters ended up 
being a bit dated but did give me a good basis for further research.


To-dos:
=======

* Figure out docker credential store: 
  https://docs.docker.com/engine/reference/commandline/login/#credentials-store

* Figure out how to get the webui thingie working.
* Figure out how to configure registry searches.
