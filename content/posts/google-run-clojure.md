+++
draft = false
date = 2020-03-18T23:55:02Z
title = "Clojure app on Google Cloud Run"
description = "Document with solution of interview tasks with handbook"
slug = ""
tags = ["Clojure", "GitHub Action", "GCP", "Telegram", "Cloud Run"]
categories = ["tutorials", "programming"]
externalLink = ""
series = ["GitHub Action"]
+++

# Welcome

I want to create a small pipeline based on GCP Run and GitHub Action.
Also increasing skills while #statathome is the best
possible solution for spending time. Let's make some real stuff.

## Tools used in this episode

- Google Cloud Platform
- Terraform
- Docker
- Clojure
- Github Action

## Google Cloud Platform

### Why Google Cloud Platform

I like Web GUI, command-line tools, GKE.
I also have some credits to use.
Cloud Run is very nice and cheap for a one-docker small app.

### Let's code - Google Cloud Platform

1. Create a new project

    ```console
    gcloud projects create [PROJECT_ID] --enable-cloud-apis

    # --enable-cloud-apis
    # enable cloudapis.googleapis.com during creation
    # example
    # gcloud projects create my-small-gcp-project --enable-cloud-apis
    ```

1. Enable services

    ```console
    gcloud services list --available | grep -e run -e compute -e container
    gcloud services enable compute.googleapis.com
    gcloud services enable container.googleapis.com
    gcloud services enable run.googleapis.com
    ```

1. Set project name

    ```bash
    gcloud config set project my-small-gcp-project
    ```

1. Create a service account and add necessary permission

    ```console
    gcloud iam service-accounts create ci-cd-user \
    --description "Account for interact with GCP Run, CR and GitHub" \
    --display-name "my-github-user"
    ```

    ```console
    gcloud projects add-iam-policy-binding my-small-gcp-project \
    --member \
    serviceAccount:ci-cd-user@my-small-gcp-project.iam.gserviceaccount.com \
    --role roles/compute.admin
    ```

    ```console
    gcloud projects add-iam-policy-binding my-small-gcp-project \
    --member \
    serviceAccount:ci-cd-user@my-small-gcp-project.iam.gserviceaccount.com \
    --role roles/run.serviceAgent
    ```

    ```console
    gcloud projects add-iam-policy-binding my-small-gcp-project \
    --member \
    serviceAccount:ci-cd-user@my-small-gcp-project.iam.gserviceaccount.com \
    --role roles/run.admin
    ```

    ```console
    gcloud projects add-iam-policy-binding my-small-gcp-project \
    --member \
    serviceAccount:ci-cd-user@my-small-gcp-project.iam.gserviceaccount.com \
    --role roles/storage.admin
    ```

## Terraform

### Why Terraform

I like working with IaaC approach and I need some testing machine.
Especially for docker part, I don't like to work with Docker for Windows.
Also if we want to reproduce solutions everywhere
that's the fastest solution. Also sometimes ago I decided that
running playgrounds in clouds is cheaper and faster than taking
care of the workstation. With IaaC I need to have only terminal and code
editor.

### Let's code - Terraform

1. Getting project credentials in JSON.

    ```console
    gcloud iam service-accounts keys create auth.json \
    --iam-account ci-cd-user@my-small-gcp-project.iam.gserviceaccount.com
    ```

1. Add `auth.json` to `.gitigonre`

    ```bash
    echo "auth.json" > .gitignore
    echo ".terraform/" >> .gitignore
    ```

1. Create `main.tf`

    ```hcl {linenos=table}
    locals {
        region_eu = "europe-west3-a"
        p_name = "my-small-gcp-project"
    }

    provider "google" {
        credentials = file("auth.json")
        project     = local.p_name
        region      = local.region_eu
    }

    // Terraform plugin for creating random ids
    resource "random_id" "instance_id" {
        byte_length = 8
    }

    // A single Google Cloud Engine instance
    resource "google_compute_instance" "default" {
    count = 1
    name         = "build-machine${random_id.instance_id.hex}"
    machine_type = "e2-medium"
    zone         = local.region_eu

    boot_disk {
    initialize_params {
        image = "ubuntu-1804-bionic-v20200129a"
    }
    }
    metadata = {
        // everyone has rsa key, right ?
        ssh-keys = "kuba:${file("~/.ssh/id_rsa.pub")}"
    }

    // Make sure flask is installed on all new instances for later steps
    metadata_startup_script = "sudo apt-get update; sudo apt-get upgrade -y; "

    network_interface {
    network = "default"
        access_config {
        // Include this section to give the VM an external ip address
        }
    }
    }

    resource "google_compute_firewall" "default" {
        name    = "app-firewall"
        network = "default"

    allow {
        protocol = "tcp"
        ports    = ["80"]
        }
    }

    // A variable for extracting the external ip of the instance
    output "m1" {
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

## Clojure

### Why Clojure

Functional, dynamic type language. Dialect of Lisp, with Lisp the code-as-data philosophy
and a powerful macro system. Not very popular,
but I like it. Also working with a various solution is always fun.

### Let's code - Clojure

1. Setup Clojure

    1. Install java on Linux

        ```bash
        sudo apt install openjdk-8-jre-headless -y
        java -version
        ```

    1. Install Clojure on Linux

        ```console
        curl -O https://download.clojure.org/install/linux-install-1.10.1.536.sh
        chmod +x linux-install-1.10.1.536.sh
        sudo ./linux-install-1.10.1.536.sh
        ```

    1. Install Leiningen

        ```console
        wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein \
        -O /usr/bin/lein
        chmod a+x /usr/bin/lein
        lein
        ```

1. Run new project

    ```bash
    lein new app <app-name>
    cd <app-name>

    # example
    # lein new app clojure-raw-rest-api
    ```

1. Check it works

    ```bash
    cd <app-name>
    lein run

    # example
    # cd clojure-raw-rest-api

    # output
    ➜  clojure-raw-rest-api lein run
    Hello, World!
    ➜  clojure-raw-rest-api
    ```

1. Let's do TDD so tests first

    ```clojure {linenos=table}
    ;test/clojure_raw_rest_api/core_test.clj
    ...
    (ns clojure-raw-rest-api.core-test
    (:require [clojure.test :refer :all]
                [clojure-raw-rest-api.core :refer :all]
                [ring.mock.request :as mock]))

    (deftest simple-page-test
    (is (= (simple-page (mock/request :get "/"))
            {:status  200
            :headers {"Content-Type" "text/html"}
            :body    "<h1>Hello World</h1>"})))

    (deftest app-status-test
    (is (= (app-status (mock/request :get "/status"))
            {:status  200
            :headers {"Content-Type" "text/json"}
            :body    {:status "ok"}})))

    (deftest enviroment-name-test
    (is (= (enviroment-name (mock/request :get "/env"))
            {:status  200
            :headers {"Content-Type" "text/json"}
            :body    {:enviroment "dev"}})))

    (deftest enviroment-missing-handler
    (is (= (missing-handler (mock/request :get "/test"))
            {:status  404
            :headers {"Content-Type" "text/html"}
            :body {:status "Error, path not found!"}})))
    ```

1. Make a basic REST API implementation

    ```clojure {linenos=true}
    ;src/clojure_raw_rest_api/core.clj
    ...
    (ns clojure-raw-rest-api.core
    (:require [ring.adapter.jetty :as jetty]
        [ring.middleware.params :refer [wrap-params]]
        [ring.middleware.reload :refer [wrap-reload]]
        [ring.middleware.keyword-params :refer [wrap-keyword-params]]
        [ring.middleware.json :refer [wrap-json-params wrap-json-response]]
        [clojure.java.io :as io]
        [clj-http.client :as client])
    (:gen-class))

    ; Read enviroment variable
    (def env (or (System/getenv "env") "dev"))

    ; Simple page
    (defn simple-page [req]
    {:status  200
    :headers {"Content-Type" "text/html"}
    :body    "<h1>Hello World</h1>"})

    ; Return Health Check
    (defn app-status [req]
    {:status  200
    :headers {"Content-Type" "text/json"}
    :body    {:status "ok"}})

    ; Return env(env var)
    (defn enviroment-name [req]
    {:status  200
    :headers {"Content-Type" "text/json"}
    :body    {:enviroment env}})

    ; Return when no path
    (defn missing-handler [request]
    {:status 404
    :headers {"Content-Type" "text/html"}
    :body {:status "Error, path not found!"}})

    (def routes [
        {:methods #{:get} :path "/" :handler simple-page}
        {:methods #{:get} :path "/status" :handler app-status}
        {:methods #{:get} :path "/env" :handler enviroment-name}
    ])

    (defn route-match? [request route]
    (and ((:methods route) (:request-method request))
        (= (:path route) (:uri request))))

    (defn app [request]
    (let [route (first (filter (partial route-match? request) routes))
            handler (get route :handler missing-handler)]
        (println "app request "
        (:request-method request) (:uri request) (pr-str route))
        (handler request)))

    (defn with-middleware [handler]
    (-> handler
        (wrap-reload)
        (wrap-keyword-params)
        (wrap-json-params {})
        (wrap-params {})
        (wrap-json-response {:pretty true})))

    (defn -main []
    (let [port (Integer. (or (System/getenv "PORT") 8081))]
        (jetty/run-jetty (with-middleware app) {:port port :join? false})))
    ```

1. Ahh and `project.clj` update

    ```clojure {linenos=table}
    (defproject clojure-raw-rest-api "1.0.0"
    :license {:name "EPL-2.0 OR GPL-2.0-or-later WITH Classpath-exception-2.0"
                :url "https://www.eclipse.org/legal/epl-2.0/"}
    :dependencies [[org.clojure/clojure "1.10.0"]
        [ring/ring-jetty-adapter "1.4.0"]
        [ring/ring-json "0.4.0"]
        [ring/ring-devel "1.4.0"]
        [clj-http "2.2.0"]
        [ring/ring-mock "0.4.0"]]
    :main ^:skip-aot clojure-raw-rest-api.core
    :target-path "target/%s"
    :profiles {:uberjar {:aot :all}})
    ```

1. Then run test

    ```bash
    lein test

    # output
    ➜  clojure-raw-rest-api lein test

    lein test clojure-raw-rest-api.core-test

    Ran 4 tests containing 4 assertions.
    0 failures, 0 errors.
    ➜  clojure-raw-rest-api ✗
    ```

1. Create jar

    ```bash
    lein uberjar

    # output
    ➜  clojure-raw-rest-api git:(master) ✗ lein uberjar
    Compiling clojure-raw-rest-api.core
    2020-03-19 11:36:40.298:INFO::main: Logging initialized @3998ms
    Created /home/kuba/Desktop/Projekty/clojure-raw-rest-api/target/uberjar/clojure-raw-rest-api-1.0.0.jar
    Created /home/kuba/Desktop/Projekty/clojure-raw-rest-api/target/uberjar/clojure-raw-rest-api-1.0.0-standalone.jar
    ```

1. Great now I'm ready to pack it into Docker container

## Docker

### Why Docker

I want to have a container. At this point, I'm familiar with Docker,
however, I need to take a look an another solution like distroless.

### Let's code - Docker

1. Install docker on VM

    ```bash
    sudo apt install docker.io
    ```

1. Add user to correct group

    ```bash
    sudo usermod -aG docker $USER
    ```

1. Re-login to apply changes

1. Check installation

    ```bash
    docker run hello-world
    ```

### Dockerfile

1. Create Dockerfile

    ```bash
    touch Dockerfile
    ```

    ```Dockerfile {linenos=true}
    FROM clojure as builder
    RUN mkdir -p /usr/src/app
    WORKDIR /usr/src/app
    COPY COPY clojure-raw-rest-api/ ./
    RUN lein test
    RUN mv "$(lein uberjar | sed -n 's/^Created \(.*standalone\.jar\)/\1/p')" app-standalone.jar

    FROM openjdk:8-jre-alpine

    COPY --from=builder /usr/src/app/app-standalone.jar ./
    ENTRYPOINT ["java", "-jar", "app-standalone.jar"]

    EXPOSE 8081
    ```

1. Test build

    ```bsah
    docker build . -t clojure-app
    ```

1. Run app with an environment variable

    ```bash
    docker run -p 8081:80 -d -e env="staging" clojure-app
    ```

1. Test it

    ```bash
    curl  $(curl -s -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip):8081/environment
    # {"environment": "staging"}
    ```

1. Tag image

    ```bash
    export PROJECT_ID="my-small-gcp-project"
    docker tag clojure-app gcr.io/$PROJECT_ID/clojure-app:1.0.0
    ```

1. Copy `auth.json` from workstation

    ```bash
    scp auth.json kuba@<ip>:<user_home>

    # IP of remote machine
    # place to copy file
    # example
    # scp auth.json kuba@35.123.25.1:/home/kuba
    ```

1. Push to Container Registry

    ```console
    gcloud auth configure-docker
    gcloud auth activate-service-account \
    ci-cd-user@my-small-gcp-project.iam.gserviceaccount.com \
    --key-file=auth.json

    gcloud auth print-access-token | docker login \
    -u oauth2accesstoken \
    --password-stdin https://gcr.io

    docker push gcr.io/$PROJECT_ID/clojure-app:1.0.0
    ```

1. Create Cloud Run Service for prod

    ```console
    gcloud run deploy prod-awesome-clojure-api \
    --platform managed \
    --allow-unauthenticated \
    --region europe-west1 \
    --port 8081 \
    --set-env-vars=env='production' \
    --image gcr.io/$PROJECT_ID/clojure-app:1.0.0
    ```

1. Create Cloud Run Service for non-prod

    ```console
    gcloud run deploy staging-awesome-clojure-api \
    --platform managed \
    --allow-unauthenticated \
    --region europe-west1 \
    --port 8081 \
    --set-env-vars=env='staging' \
    --image gcr.io/$PROJECT_ID/clojure-app:1.0.0
    ```

1. Destroy infra that's important

    ```bash
    terraform destroy
    ```

## GitHub Action - CI/CD base

### Why GitHub Action

I like GitHub Action, I enjoy working with it.
It just works and is fast, well-documented, free, etc.
It's not a complicated application so I can't see any
reason to use Jenkins.

### Let's code - GitHub Action

1. Add 3 variables as GitHub Secrets

    1. GCP_SA_EMAIL - service account email:
      `ci-cd-user@$my-small-gcp-project.iam.gserviceaccount.com`
    1. GCP_SA_KEY - encoded `auth.json`

        ```bash
        cat auth.json | base64
        ```

    1. PROJECT_ID - project name:
      `my-small-gcp-project`

1. Put two file into `.github\workflows`

    ```bash
    touch master.yml
    touch no-master.yml
    ```

1. Push/PR to master - `master.yml`

    ```yaml {linenos=table}
    name: Build from master

    on:
    push:
        branches:
        - master

    env:
        STG_SERVICE: "staging-awesome-clojure-api"
        STG_URL: "https://staging-awesome-clojure-api-jsrwhbaamq-ew.a.run.app"
        PROD_SERVICE: "prod-awesome-clojure-api"
        PROD_URL: "https://prod-awesome-clojure-api-jsrwhbaamq-ew.a.run.app"
        APP_NAME: "clojure-app"

    jobs:
    build-the-app:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v2
        - name: Setup GCP
          uses: GoogleCloudPlatform/github-actions/setup-gcloud@master
          with:
            version: '281.0.0'
            service_account_email: ${{ secrets.GCP_SA_EMAIL }}
            service_account_key: ${{ secrets.GCP_SA_KEY }}
            export_default_credentials: true
        - name: auth to CR
          run: gcloud auth configure-docker
        - name: build app
          run: docker build . -t $APP_NAME
        - name: tag app
          run: docker tag $APP_NAME gcr.io/${{ secrets.PROJECT_ID }}/$APP_NAME:${{ github.sha }}
        - name: push image
          run: docker push gcr.io/${{ secrets.PROJECT_ID }}/$APP_NAME:${{ github.sha }}

    deploy-to-stg:
        needs: build-the-app
        runs-on: ubuntu-latest
        steps:
        - name: Setup GCP
          uses: GoogleCloudPlatform/github-actions/setup-gcloud@master
          with:
            version: '281.0.0'
            service_account_email: ${{ secrets.GCP_SA_EMAIL }}
            service_account_key: ${{ secrets.GCP_SA_KEY }}
            export_default_credentials: true
        - name: update staging
          run: gcloud run deploy $STG_SERVICE --project ${{ secrets.PROJECT_ID }} --platform managed --region europe-west1 --image gcr.io/${{ secrets.PROJECT_ID }}/$APP_NAME:${{ github.sha }}
        - name: Check stg
          run: if [[ ! $(curl -s $STG_URL/status | grep ok) ]]; then exit 1; fi

    deploy-to-prod:
        needs: [build-the-app, deploy-to-stg]
        runs-on: ubuntu-latest
        steps:
        - name: Setup GCP
          uses: GoogleCloudPlatform/github-actions/setup-gcloud@master
          with:
            version: '281.0.0'
            service_account_email: ${{ secrets.GCP_SA_EMAIL }}
            service_account_key: ${{ secrets.GCP_SA_KEY }}
            export_default_credentials: true
        - name: update prod
          run: gcloud run deploy $PROD_SERVICE --project ${{ secrets.PROJECT_ID }} --platform managed --region europe-west1 --image gcr.io/${{ secrets.PROJECT_ID }}/$APP_NAME:${{ github.sha }}
        - name: Check stg
          run: if [[ ! $(curl -s $PROD_URL/status | grep ok) ]]; then exit 1; fi
        - run: "echo PROD status: ${{ steps.get_prod_status.response }}"
    ```

1. Push/PR to not master - `no-master.yml`

    ```yaml {linenos=table}
    name: Build from no-master

    on:
    push:
        branches:
        - '*'
        - '!master'
    pull_request:
        branches:
        - '*'

    jobs:
    build-test-docker:
        runs-on: ubuntu-latest
        steps:
        - uses: actions/checkout@v2
        - name: build app
        run: docker build . -t clojure-app
    ```

## Bonus - Telegram

### Why Telegram

I use Telegram every day, build are long so
I decided to add a notification.

### Let's code - Telegram

1. Add to `master.yaml`

    ```yaml {linenos=table}
    send-notification:
      needs: [build-the-app, deploy-to-stg, deploy-to-prod]
      runs-on: ubuntu-latest
      steps:
      - name: test telegram notification
        uses: appleboy/telegram-action@master
        with:
          to: ${{ secrets.TELEGRAM_TO }}
          token: ${{ secrets.TELEGRAM_TOKEN }}
          message: Build number ${{ github.run_number }} of ${{ github.repository }} is complete ;)
    ```

1. Telegram configuration

    1. type `/help`
    1. type `/newbot`
    1. generate bot name like `superbot`, not unique
    1. generate bot username like `super-uniqe-bot`, must be unique
    1. get a token `/token`
    1. save token
    1. subscribe bot
    1. use REST API to received `TELEGRAM_TO`

        ```bash
        curl -s https://api.telegram.org/bot<token>/getUpdates | jq.

        # example URL
        # https://api.telegram.org/bot123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11/getUpdates
        ```

    1. `TELEGRAM_TO` is field `chat.id` - 353824382

1. Configure notification

    I would like to get some notification after the build.
    Telegram is a nice tool, and there is already created [GH Action][7].

    ```yaml {linenos=table}
    - name: test telegram notification
      uses: appleboy/telegram-action@master
      with:
        to: ${{ secrets.TELEGRAM_TO }}
        token: ${{ secrets.TELEGRAM_TOKEN }}
        message: Build number ${{ github.run_number }} of ${{ github.repository }} is complete ;)
    ```

    That snipped contains two secrets `secrets.TELEGRAM_TO`
    and `secrets.TELEGRAM_TOKEN`.
    Again I can recommend this [docs][3].
    But I received this value in the previous section. \

    There are also two context variable `github.run_number` and `github.repository`.
    And again [docs][4] are more than enough.

## Logging

I use Google Cloud Run, so Google manages all logs from services.
In the case of this architecture usage, `normal` logs collector
is an overstatement.
![just logs](/images/google-run-clojure-logs.png)

## Monitoring and alerts

For this, I decided to use the basic features of GCP.

### Uptime Checks

1. Go to `Monitoring` -> `Create uptime checks`

![just uptime](/images/google-run-clojure-uptime.png)

### Alerting policies

1. Go to `Monitoring` -> `Create alerting policies`

![just alert](/images/google-run-clojure-alert.png)

## Summary

That was a nice project. I have the opportunity to learn about IAM and GCP Run.
Also, I have a better understanding of GitHub Action pipelines.
Clojure looks a bit strange,
but testing functional code is sweet. I never write such readable test cases.
The source code of the project is [here][5], feel free to use.

[1]: https://help.github.com/en/github/getting-started-with-github/create-a-repo
[2]: https://console.cloud.google.com/apis/credentials/serviceaccountkey
[3]: https://core.telegram.org/bots/api
[4]: https://help.github.com/en/actions/reference/
[5]: https://github.com/3sky/upgraded-octo-winner