+++
draft = false
date = 2020-03-01T22:19:54Z
title = "Continuous delivery for static blog"
description = "Deliver with style"
slug = ""
tags = ["Travis ci", "Circle ci"]
categories = ["tutorials", "cd"]
externalLink = ""
series = ["GitHub Pages"]
+++

# Welcome

I'm still writing about my blog, just ordinary auto-promotion.
However, I'll try to make this particular article useful
even in a different context than blogs.
The next few lines will be dedicated to continuous delivery
(without continuous integration/testing). \
As I showed in previous issues manual work is
easy and in some case fast. Unfortunately,
it's also boring, prone to errors and time-consuming.
How to achieve good results without self-hosted CI servers,
expensive solution or custom scripts on VPS?
At this moment in time(29022020) I know only
two nice and easy tools that meet my assumptions.
Which one will be better? Let's check it.

Ahh I forgot one important thing what this whole CD is: \
[*Continuous delivery*][2] (CD or CDE) is a software
engineering approach in which teams produce software
in short cycles, ensuring that the software can be
reliably released at any time and, when releasing
the software, doing so manually. It aims at building,
testing, and releasing software with greater speed
and frequency. The approach helps reduce the cost,
time, and risk of delivering changes by allowing for
more incremental updates to applications in production.
A straightforward and repeatable deployment process is important for continuous delivery.

## Description of scenario

1. Push new article into [source code][5] repo, should start building.
1. Download repository
1. Install `Hugo`
1. Build static content
1. Push into [Page][6] repo

## Tools used in this episode

- Travis CI
- CircleCI
- GitHub Action

## Travis CI

As a continuous integration platform, [Travis CI][1] supports your
development process by automatically building and testing code changes,
providing immediate feedback on the success of the change.
Travis CI can also automate other parts of your development
process by managing deployments and notifications.

### Why Travis CI

Travis CI is another popular tool that is free for open-source projects.
Widely used by many companies like [Zendesk][3] or [Heroku][4].
If I remember correctly is quite easy, but only "war never changes"...

### Let's code - Travis CI

1. Login into the webpage travis-ci.org with the GitHub account.
1. Add a new project by clicking `+` and select correct [repo][5].

![travis-add](/images/blog-cds-travis-add.png)

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
    TIMESTAMP=$(date +%s)
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
    git commit --message "CI Build: $TIMESTAMP"

    git remote set-url origin \
    https://3sky:${GH_TOKEN}@github.com/3sky/3sky.github.io.git > /dev/null 2>&1
    git push --quiet --set-upstream origin master
    ```

1. Add GitHub token as `GH_TOKEN`

    1. Official [doc][7] This is a better source.

### Summary - Travis CI

It's taken me several attempts to configure the whole process,
maybe because it's not a regular build pipeline. After that,
I need to figure out how looks file structure,
but here very helpful was debug method called `pwd && ls -l`.
Configuration GitHub credentials, repo paths, etc was easy and fast.
Installing `hugo` from the snap repository was also hassle-free.
In my case, this solution is more than OK.
Everything just works, I can re-use almost whole my script
and documentation are neat.

## CircleCi

Rather a small description of the product on the official website.
`We build CI/CD so you can build the next big thing.` - circleci.com.
I like this slogan it's trendy if you are managers.

### Why CircleCi

[CircleCi][8] is more focused on large companies.
Used by Facebook, Spotify, etc.
UI is nice and elegant like enterprise solutions for
managers and product owners. However,
is also free for open source usage and
I have worked with this solution in the past.

### Let's code - CircleCi

1. Login into circleci.com with the usage of the GitHub account as well.
1. Add project.
    Adding a project it's easy, after that you get information about
    suggested CircleCI configuration. That's the example "Hello World"

    ```yaml
    # Use the latest 2.1 version of CircleCI pipeline process engine. See: https://circleci.com/docs/2.0/configuration-reference
    version: 2.1
    # Use a package of configuration called an orb.
    orbs:
    # Declare a dependency on the welcome-orb
    welcome: circleci/welcome-orb@0.4.1
    # Orchestrate or schedule a set of jobs
    workflows:
    # Name the workflow "welcome"
    welcome:
        # Run the welcome/run job in its own container
        jobs:
        - welcome/run
    ```

    Unfortunately, I want to add my custom solution.

1. Add my own `.circleci/config.yml` in the root of the repository.

    ```yaml
    version: 2.1
    jobs:
    build:
        docker:
        # the primary container, where your job's commands are run
        - image: jguyomard/hugo-builder
        steps:
        - checkout # check out the code in the project directory
        - run:
            name: run deploy.sh
            command: |
                sh ./deploy.sh
    ```

1. And of course, do not forget about Environment Variable called `GH_TOKEN`.
1. As you may see I decided to re-use once again my `deploy.sh` script.
1. Push your code to the repository and watch what is going on.

    ```bash
    git add -A && git commit -m 'circleci test #1' & git push

    # Useful tip use #<incrising number>,
    # that saves you from commits message like `fixxxxx`
    ```

1. A great success, I just set up two CI system to my small blog page.

### Summary - CircleCi

Worth to notice is a fact that `CircleCi` is using
custom dockers images as a build base. When you realized
it the world will be a better place to live. Why it's fantastic?
You can create your container image and just use it.
It's faster especially If you use some massive custom stuff.
On another hand, a configuration is much more complicated - `job`,
`workflows`, `pipeline`, basic docker's understanding. Personally,
I hate this Web GUI. Slow, unintuitive, design reminds me of some
time tracking corporate tools.

## GitHub Actions

GitHub Actions make it easy to automate all your
software workflows, now with world-class CI/CD. Build,
test, and deploy your code right from GitHub. Make code
reviews, branch management, and issue triaging work the way you want.

### Why GitHub Actions

[GitHub Actions][9] is a quite new product, especially
for a public repo. First [blog post][10] I found is
from `2019-08-08`. I never use it before, so that could
be quite an interesting adventure. Happily, where is
a lot of example on the Internet, what could go wrong then?

### Let's code - GitHub Actions

1. Click `Action` button in [blog-src][5] page.
1. Then `Skip this: Set up a workflow yourself`.
    Because real men do not read documentation :) That's a joke.
    Creator is easier to use than exploring all this template.
1. I need to add one file `.github/workflow/main.yaml`

    ```yaml
    name: CI

    on: [push]

    jobs:
    build:

        runs-on: ubuntu-latest

        steps:
        - uses: actions/checkout@v2
        - name: Run a one-line script
          run: echo Hello, world!
        - name: Install Hugo
          run: sudo snap install hugo
        - name: Run deploy.sh
          env:
            # Here we need to declar secret directly for a first time
            GH_TOKEN: ${{ secrets.GH_TOKEN }}
          run: sh ./deploy.sh
    ```

1. Also, I set `GH_TOKEN` as a repository `SECRET`.
1. Now I need only push my code.

    ```bash
    git add -A && git commit -m 'GitHub test #1' & git push
    ```

1. After that, I go to the action tab a see how my build looks like.

### Summary - GitHub Actions

To be honest GitHub Action surprised me.
It's surprisingly easy to set up, even with compare to Travis.
Jobs lunch fast, without delays. What I can say more?
I have a problem with finding some issues related to this
solution at this point in my side project maturity.

## Global summary

This comparison will be focused on my current case,
not about all the good, bad and ugly sides of these projects.
I would like to highlight that all tested solutions are great,
easy to set up and free for public projects. Developers provide solid
documentation, `StackOverflow` wasn't mandatory.
All solutions are stable and `Getting Things Done`. \
In the beginning, I would like rejected `CircleCI`,
because of this Web GUI. Maybe if you're a manager
or you just like clicking then it is a product for you,
for me is uncomfortable and hard to read. CircleCI from my
feeling is a bit slower than others. The level of
complication is high, even with simple projects.
Maybe if you have a big complicated project it's awesome,
but for me is overkill. \
Here I have a problem, both tools really
good fit to my case. Web GUIs are simple and
effective, the YAML file is simple and user-friendly.
I think GitHub Action is faster than competitors for
an obvious reason - repo is hosted on GitHub so within
one product. Travis has a long history, so he should
be mature and well tested. \
After few minutes of thinking I decided
to stay with GitHub Action for a few months longer than
I expected. Just because doesn't need an additional tool
and looks promising. \
What next? `Automatic Tests`. Definitely,
but I have no idea how to test Markdown and static content.

[1]: https://travis-ci.org/
[2]: https://en.wikipedia.org/wiki/Continuous_delivery
[3]: https://www.zendesk.com/
[4]: https://www.heroku.com/
[5]: https://github.com/3sky/blog-src
[6]: https://github.com/3sky/3sky.github.io
[7]: https://docs.travis-ci.com/user/environment-variables/#defining-variables-in-repository-settings
[8]: https://circleci.com
[9]: https://github.com/features/actions
[10]: https://github.blog/2019-08-08-github-actions-now-supports-ci-cd/