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

Commands:
=========

docker image prune -a -f 
  Removes all unused images; doesn't ask for confirmation

docker build -t ${name} .
  Builds an image from the Dockerfile named/tgged w/var *-t*

docker run --rm ...
  --rm arg automatically removes the container when it exits...
  no having to run a second command.

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


To-dos:
=======

* Figure out docker credential store: 
  https://docs.docker.com/engine/reference/commandline/login/#credentials-store


