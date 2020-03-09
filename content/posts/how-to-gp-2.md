+++
draft = false
date = 2020-02-26T22:55:46Z
title = "How to use GitHub Pages #2"
description = "GitHub page at the hard way"
slug = ""
tags = ["GCP", "Terraform", "Hugo", "Nginx"]
categories = ["tutorials"]
externalLink = ""
series = ["GitHub Pages"]
+++

# Welcome

In the previous episode, I have created a short
blog post about `short blog post`. That was quite
interesting for me, in meantime, I configure my VSC for English
support, add some small fixes in the Markdown file then I realized
that the manual reload of configuration is a huge mistake in the
context of productive. What is the first tool when we start thinking
about automation? In Linux environment of course. For me, it's `Bash`.
Let's begin then.

## Tools used in this episode

- Bash
- GitHub Pages

## Bash

[Bash][1] is an sh-compatible shell
that incorporates useful features from the Korn shell (ksh) and C shell (csh)

### Why Bash

Bash is everywhere, on almost every modern *nix system.
Maybe it's not most readable language, but if you have
at least small idea what you want to achieve,
then that's enough to automate it with `Bash`

### Let's code - Bash

1. Go inside `3sky.io` and open a new file

    ```bash
    cd <page-name>
    vim <script>.sh

    # Example
    # cd 3sky.io
    # vim deploy.sh
    ```

1. Write a script

    ```bash
    #!/bin/bash
    set -e
    # -e = Exit immediately if a command exits with a non-zero status

    # Set as hardcode, it's easier
    PROJECT_DIR=/home/kuba/3sky.io

    # Cleanup public directory
    # Always be sure what you delete
    rm -rf $PROJECT_DIR/public

    # Generate static
    cd $PROJECT_DIR
    hugo

    # Copy directory
    sudo cp -R $PROJECT_DIR/public /var/www/

    # Change owner of file
    sudo chown -R \
    $(ps aux|grep nginx|grep -v grep| grep -v master| cut -d" " -f1).\
    /varwww/public/

    # Restart Nginx
    sudo systemctl restart nginx.service
    ```

    It's very similar to steps from the previous post, isn't it?

1. Add execution permission

    ```bash
    chmod +x <script>.sh

    # Example
    #chmod +x deploy.sh
    ```

1. Check how it works

    ```bash
    ./deploy.sh
    ```

### Summary - Bash

After that small intervention,
I cat reload my developer service after every
update without any problems or manual work. The important fact is
that the bash script works and is stable. Not everything is as
pleasant as not repeating boring work. Now it's time for go-live.

## GitHub Pages

[GitHub Pages][2] is a static site
hosting service that takes HTML, CSS, and JavaScript
files straight from a repository on GitHub, optionally runs
the files through a build process and publishes a website.
You can see examples of GitHub Pages sites in the GitHub Pages examples collection.

### Why GitHub Pages

We already talk about that, it's free
and till writing this series I didn't hear
any complaints. Also,
I have a simple [documentation][3]. So why not?

### Let's code - GitHub Pages

1. Create a GitHub

    ```bash
    git clone https://github.com/username/username.github.io

    # Example
    # git clone https://github.com/3sky/3sky.github.io
    ```

1. Great, now we should treat this directory as Nginx's  `public` directory.

    ```bash
    cp -R public/* username.github.io

    # Example
    # cp -R public/* 3sky.github.io
    ```

1. Now just push it

    1. Go to directory

        ```bash
        cd 3sky.github.io
        ```

    1. Add all file under tracking

        ```bash
        git add -A
        ```

    1. Configure user and email

        ```bash
        git config --global user.name "FIRST_NAME LAST_NAME"
        git config --global user.email "MY_NAME@example.com"

        # Example
        # git config --global user.name "3sky"
        # git config --global user.email "3sky@protonmail.com"
        ```

    1. Add commit message

        ```bash
        git commit -m 'my first blog commit'
        ```

    1. Push it

        ```bash
        git push
        ```

    1. Now provide some credentials I can recommend tokens for machines like GCP.
        1. Use this [guid][4] - it's better to use original docs.
        1. Type you're user and token.

            ```bash
            kuba@app-9545cd49c0a34f27:~/3sky.github.io$ git push
            Username for 'https://github.com': 3sky
            Password for 'https://3sky@github.com':
            ```

        1. And I'm done blog is live, but...

#### Summary - GitHub Pages

It's working very slow.
My first deployment lasted more than 1hour,
so take a breath and just go for a walk,
I can recommend a long walk. What will be next?
CD system, but which one? And what about automatic test?
You can ask now `why the heck I need automatic tests?`.
Because if something takes so long, it's better to deploy
a stable and tested version.

[1]: https://www.gnu.org/software/bash/
[2]: https://help.github.com/en/github/working-with-github-pages/about-github-pages
[3]: https://pages.github.com/
[4]: https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line
