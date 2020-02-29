+++
draft = false
date = 2020-02-29T22:19:54Z
title = "How deliver blog page"
description = "Deliver with style"
slug = ""
tags = ["Travis ci", "Circle ci"]
categories = ["tutorials", "cd"]
externalLink = ""
series = ["GitHub Pages"]
+++

I'm still writing about my blog, just ordinary auto promotion. However I'll try make this particular article useful even in different context than blogs. The next few lines will be dedicated to continuous delivery (without continuous integration/testing). \
As I showed in previous issues manual work is easy and in some case fast. Unfortunately it's also boring, prone to errors and time consuming. How to achieve good results without self-hosted CI servers, expensive solution or custom scripts on VPS? At this moment in time(29022020) I know only two nice and easy tools which meet my assumptions. Which one will be better? Let's check it.

Ahh I forgot one important thing what this whole CD is: \
[*Continuous delivery*][2] (CD or CDE) is a software engineering approach in which teams produce software in short cycles, ensuring that the software can be reliably released at any time and, when releasing the software, doing so manually. It aims at building, testing, and releasing software with greater speed and frequency. The approach helps reduce the cost, time, and risk of delivering changes by allowing for more incremental updates to applications in production. A straightforward and repeatable deployment process is important for continuous delivery.

## Description of scenario

1. Push new article into [source code][5] repo, should start build.
1. Download repository
1. Install `Hugo`
1. Build static content
1. Push into [Page][6] repo

## Tools used in this episode

- Travis CI
- Circle CI
- GitHub Action(zero knowledge)

## Travis CI

As a continuous integration platform, [Travis CI][1] supports your development process by automatically building and testing code changes, providing immediate feedback on the success of the change. Travis CI can also automate other parts of your development process by managing deployments and notifications.

### Why?

Travis CI is another popular tool which is free for open source projects. Widely used by many companies like [Zendesk][3] or [Heroku][4]. If I remember correctly is quite easy, but only "war never changes"...

#### Let's code

1. Login into webpage https://travis-ci.org/.
1. Add new project by clicking `+` and select correct [repo][5].
![alt text](images/img-blog-cds/travis-add.png "Add new project")
1. Add small `.travis.yml` file:

    ```yaml
    dist: xenial
    addons:
    snaps:
        - hugo

    deploy:
        provider: script
        script: bash deploy.sh
        on:
    branch: master
    ```

1. Do You remember our script `run.sh`, now need some modification

    ```bash
    #!/bin/bash
    set -e
    # -e = Exit immediately if a command exits with a non-zero status

    # get hugo version
    hugo version

    # Cleanup public directory
    rm -rf public

    # Generate static
    hugo

    # Clone page repo
    git clone https://github.com/3sky/3sky.github.io

    # Copy content
    cp -R public/* 3sky.github.io

    # Push to repo
    cd 3sky.github.io

    # Push tp repo with token
    git config --global user.email "3sky@protonmail.com"
    git config --global user.name "3sky"

    git add -A
    git commit --message "Travis build: $TRAVIS_BUILD_NUMBER"

    git remote set-url origin https://3sky:${GH_TOKEN}@github.com/3sky/3sky.github.io.git >/dev/null 2>&1
    git push --quiet --set-upstream origin master
    ```

1. Add GitHub token as `GH_TOKEN`

    - Official [doc][7] This is better source.

#### Summary

It's take me several attempts to configure whole process, maybe because it's not regular build pipeline. After that I need to figure out how looks file structure, but here very helpful was debug method called `pwd && ls -l`. Configuration GitHub credentials, repo paths, etc was easy and fast. Installing `hugo` from snap repository was also hassle-free. For my case this solution is more than OK. Everything just works, I can reuse almost re-use my script, and documentation is neat.

[1]: https://travis-ci.org/
[2]: https://en.wikipedia.org/wiki/Continuous_delivery
[3]: https://www.zendesk.com/
[4]: https://www.heroku.com/
[5]: https://github.com/3sky/blog-src
[6]: https://github.com/3sky/3sky.github.io
[7]: https://docs.travis-ci.com/user/environment-variables/#defining-variables-in-repository-settings