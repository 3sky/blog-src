+++
draft = false
date = 2020-02-24T21:55:02Z
title = "How to use GitHub Pages #1"
description = "GitHub page at the hard way"
slug = ""
tags = ["GCP", "Terraform", "Hugo", "Nginx"]
categories = ["tutorials"]
externalLink = ""
series = ["GitHub Pages"]
+++

# Welcome

Everyone sometimes thinks about personal website.
Nothing fancy, just static content with clever topics...
sounds easy, isn't it? The only problem is how to host
this page and how to do it fast (and as cheap as is possible).
So where comes [GitHub Page][1]. The main reason why I choose
this solution is the price and domain. 3sky.github.io
will look cool, almost professional. The question is why I will
do it harder than it's recommended? The answer is simple because I can.
Technology is all about curiosity and people who like to do stuff.
After a short introduction let's start.

## Tools used in this episode

- Google Cloud Platform
- Terraform
- Hugo
- Nginx

## Terraform

[Terraform][3] is a tool for building, changing,
and versioning infrastructure safely and efficiently.
Terraform can manage existing and popular service
providers as well as custom in-house solutions.

### Why Terraform

It's a very popular tool - I always want to learn how
to use it. More or less in the correct way.
Also managing infrastructure as a code it’s so satisfying.

### Let's code - Terraform

1. Getting project credentials.

    Set up a service account key, which Terraform
    will use to create and manage resources in your GCP project.
    Go to the [create service account key page][4]. Select the default
    service account or create a new one, select JSON as the key type,
    and click Create.
    This downloads a JSON file with all the credentials that will be
    needed for Terraform to manage the resources. This file should be
    located in a secure place for production projects,
    but for this example move the downloaded JSON file to the project
    directory. We will call this file `auth.json`

1. Create `main.tf`

    ```json
    // Set local variable
    locals {
        region_eu = "europe-west3-a"
        project_name = "tokyo-baton-256120"
    }


    provider "google" {
        credentials = file("auth.json")     // path to `auth.json`
        project     = local.project_name
        region      = local.region_eu
    }


    // Terraform plugin for creating random ids
    resource "random_id" "instance_id" {
        byte_length = 8
    }

    // A single Google Cloud Engine instance
    resource "google_compute_instance" "default" {
        // count of instances
        count = 1
        // define name with random_id plugin
        name         = "app-${random_id.instance_id.hex}"
        // size of instance
        machine_type = "f1-micro"
        zone         = local.region_eu

    boot_disk {
        initialize_params {
            // image from GCP image list
            image = "ubuntu-1804-bionic-v20200129a"
        }
    }

    metadata = {
        // existing ssh key of kuba's
        ssh-keys = "kuba:${file("~/.ssh/id_rsa.pub")}"
    }

    // Make sure nginx is installed on all new instances for later steps
    metadata_startup_script = "sudo apt-get update;
    sudo apt-get install -yq nginx;"

    network_interface {
        network = "default"
            access_config {}
        }
    }


    data "google_compute_subnetwork" "my-subnetwork" {
        name   = "default-${local.region_eu}"
        region = "europe-west3"
    }

    // app-firewall open for incoming request on port 80
    resource "google_compute_firewall" "default" {
        name    = "app-firewall"
        network = "default"

        allow {
            protocol = "tcp"
            ports    = ["80"]
        }
    }

    // A variable for extracting the external ip of the instance
    output "ip" {
        value = "${google_compute_instance.default.0.network_interface.0.access_config.0.nat_ip}"
    }
    ```

1. Initialize a working directory containing Terraform configuration files

    ```bash
    terraform init
    ```

1. Apply the changes required to reach the desired state of the configuration

    ```bash
    terraform apply
    ```

1. Connect to instance via ssh

    ```bash
    ssh user@ip

    # user = form line `metadata` secion
    # ip = from `ip` variable output
    # Example
    # ssh kuba@35.123.25.1
    ```

1. Destroy the Terraform-managed infrastructure

    `WARNING` - At the end of learning session
    destroy unused infrastructure - it's cheaper

    ```bash
    terraform destroy
    ```

### Summary - Terraform

That was easy, isn't it? But remember it's infrastructure
working on someone's else machines - you need to pay for it.
Use Terraform wisely.

## Hugo

[Hugo][5] is one of the most popular open-source
static site generators. With its amazing speed and
flexibility, Hugo makes building websites fun again

### Why Hugo

Hugo is open-source and written in Go. In compare to Jekyll(Ruby) choice was easy.

### Let's code - Hugo

1. Install Hugo with the correct version

    ```bash
    sudo snap install hugo
    ```

1. Generate a new site

    ```bash
    hugo new site <page-name>

    # Example
    # hugo new site 3sky.io
    ```

1. Go inside new project directory

    ```bash
    cd <page-name>
    # Exxample
    # cd 3sky.io
    ```

1. Select theme from [Hugo Themes][2]

    ```bash
    git init
    git submodule add <url of themes from github> themes/<themes name>
    # Example
    # git submodule add https://github.com/luizdepra/hugo-coder.git themes/hugo-coder
    ```

1. Configure your `config.toml`

    1. Open `config.toml`

        ```bash
        vim config.toml
        ```

    1. Setup minimal config

        ```toml
        title = "Personal blog"
        theme = "hugo-coder"
        languagecode = "en"
        defaultcontentlanguage = "en"
        paginate = 20
        canonifyurls = true
        pygmentsstyle = "emacs"
        pygmentscodefences = true
        pygmentscodefencesguesssyntax = true
        # The personal key for counting users with Google Analytics
        googleAnalytics = "UA-159451243-1"
        # Maybe you want to comment somethig with disqus?
        disqusShortname = "3sky"

        [params]
            author = "Jakub Wołynko"
            info = "IT Developer"
            description = "Clean and minimal blog about IT"
            keywords = "blog,developer,personal"
            favicon_32 = "images/f32.png"
            favicon_16 = "images/f16.png"
        avatarurl = "images/avatar.jpg"
            footercontent = "Hosted for free by GitHub :*"
            hidecredits = false
            hidecopyright = false
            rtl = false
        [taxonomies]
            category = "categories"
            series = "series"
            tag = "tags"
        # Social links
        [[params.social]]
            name = "Github"
            icon = "fab fa-github fa-2x"
            weight = 1
            url = "https://github.com/3sky/"
        [[params.social]]
            name = "LinkedIN"
            icon = "fab fa-linkedin"
            weight = 2
            url = "https://www.linkedin.com/in/jakubwolynko/"
        [[params.social]]
            name = "Twitter"
            icon = "fab fa-twitter fa-2x"
            weight = 3
            url = "https://twitter.com/kuba_wolynko/"
        # Menu links
        [[menu.main]]
            name = "Blog"
            weight = 1
            url  = "/posts/"
        [[menu.main]]
            name = "About"
            weight = 2
            url = "/about/"
        ```

1. Add the first post

    ```bash
    hugo new posts/hello-world.md
    ```

1. Customize it!

    ```bash
    vim content/posts/hello-world.md
    ```

1. Add `about` section

    ```bash
    hugo new about.md
    ```

1. Customize it!

    ```bash
    vim content/about.md
    ```

1. Add avatar

    ```bash
    mkdir static/images
    # that's my photo from Twitter
    wget -Ostatic/images/avatar.jpg \
    https://pbs.twimg.com/profile_images/1219265057265266688/ANJwVv2o_400x400.jpg
    ```

1. Uff now you're ready - generate your static site.

    ```bash
    hugo
    ```

### Summary - Hugo

Now you have folder `public` with static
content of your page. What's next? Upload to GitHub?
No, that will be too fast and too easy.
We need real tests. Let's say hello to Nginx.

## Nginx

[Nginx][6] (pronounced "engine X") is a
web server that can also be used as a reverse proxy,
load balancer, mail proxy, and HTTP cache. The software
was created by Igor Sysoev and first publicly released in 2004.

### Why Nginx

Nginx is open-source, popular and fast.
Another obvious choice.

### Let's code- Nginx

1. Copy `public/` into `/var/www/`

    ```bash
    sudo cp -R public /var/www/

    # -R = copy directories recursively
    ```

1. Change owner of a file

    ```bash
    sudo chown -R  \
    $(ps aux|grep nginx|grep -v grep| grep -v master| cut -d" " -f1). \
    /var/www/public/

    # -R = copy directories recursively
    # $(ps aux|grep nginx|grep -v grep| grep -v master| cut -d" " -f1).
    # = get owner of nginx worker
        # $(). = get output as a command argument, `.` = set same group as owner

    # ps aux|grep nginx|grep -v grep| grep -v master| cut -d" " -f1
        # a = show processes for all users
        # u = display the process's user/owner
        # x = also show processes not attached to a terminal

    # grep nginx|grep -v grep| grep -v master = filter output
        # search `nginx` string
        # -v = invert the sense of matching, to select non-matching lines

    # cut -d" " -f1 = get only first column od output
        # -d" " = use " " instead of TAB for field delimiter
        # -f1 = select only these fields(1)
    ```

1. Change default config file

    1. Open file

    ```bash
    sudo vim /etc/nginx/sites-enabled/default
    ```

    1. Change root directory

        ```bash
        #line 41
        root /var/www/html;
        # into
        root /var/www/public;
        ```

1. Restart server

    ```bash
    sudo systemctl restart nginx.service
    ```

1. Check page status(should be `200 - OK`)

    ```bash
    curl -sL -w "%{http_code}\\n" localhost:80 -o /dev/null
    # -s = Silent cURL's output
    # -L = Follow redirects
    # -w = Custom output format
    # -o = Redirects the HTML output to /dev/null
    ```

1. Destroy the Terraform-managed infrastructure

    `WARNING` - At the end of learning
    session destroy unused infrastructure - it's cheaper

    ```bash
    terraform destroy
    ```

### Summary - Nginx

Now we have a working static site on
GCP instance, with the usage of Terraform and Nginx.
That's only beginning, another step will be deploying
this site just inside GitHub Pages.

[1]: https://pages.github.com/
[2]: https://themes.gohugo.io/
[3]: https://www.terraform.io/
[4]: https://console.cloud.google.com/apis/credentials/serviceaccountkey
[5]: https://gohugo.io/
[6]: https://www.nginx.com/
