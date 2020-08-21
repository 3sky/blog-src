+++
draft = false
date = 2020-08-20T20:30:02Z
title =  "Go app on Kubernetes from Scrach"
description = "Sometimes I need more custom solution or more elegant"
slug = ""
tags = ["GitHub Action", "Kubernetes", "Terraform", "Helm"]
categories = ["tutorials"]
externalLink = ""
series = ["GitHub Action"]
+++

# Welcome

I like GitHub Actions, I like Kubernetes and I want to learn more
about Helm. So maybe I should join these tools and make a smooth pipeline?
Why not? Also, I switched to Fedora, and that's a great moment to checkout
Podman in action. No time to wait, let's go.

## Tools used in this episode

- GitHub Action
- Podman
- Kubernetes
- Terraform
- Helm
- GCP
- A bit of Golang :)

## Build the app

The first step is building a small app. I decided to use
Golang because it's an awesome language for microservices
and testing is clear.

1. Create a directory for app and infra part

    ```bash
    mkdir -pv app infra
    ```

1. Go to the app directory and create `main.go`

    ```go {linenos=table}
    package main

    import "fmt"

    func main() {
       fmt.Println("Hello World!")
    }
    ```

1. Init go mod

    ```bash
    go mod init 3sky/k8s-app
    ```

### Write code

  I decided to use [Echo][1] framework,
  I like it, it's fast and logger is easy to use. \

  App has two endpoint:

- `/` - which return `Hello World!`
- `/status` - which retrun app status = `OK`

    ```go {lines=table}
    package main

    import (
        "net/http"
        "time"
        "github.com/labstack/echo/v4"
        "github.com/labstack/echo/v4/middleware"
    )
    // Greetings ...
    type Greetings struct {
        Greet string    `json:"greet"`
        Date  time.Time `json:"date"`
    }
    // Status ...
    type Status struct {
        Status string `json:"status"`
    }
    func main() {
         // Echo instance
         e := echo.New()
        // Middleware
        e.Use(middleware.LoggerWithConfig(middleware.LoggerConfig{
           Format: "method=${method}, uri=${uri}, status=${status}\n",
        }))
        e.Use(middleware.Recover())
        // Routes
        e.GET("/hello", HelloHandler)
        e.GET("/status", StatusHandler)
        // Start server
        e.Logger.Fatal(e.Start(":1323"))
    }
    // HelloHandler ...
    func HelloHandler(c echo.Context) error {
        return c.JSON(http.StatusOK, &Greetings{Greet: "Hello, World!", Date: time.Now()})
    }
    // StatusHandler ...
    func StatusHandler(c echo.Context) error {
        return c.JSON(http.StatusOK, &Status{Status: "OK"})
    }
    ```

1. Download dependences

    ```bash
    go mod tidy
    ```

1. Run the code

    ```bash
    go run main.go
    ```

1. Add some basic tests

    ```go {linenos=table}
    package main

    import (
       "encoding/json"
       "net/http"
       "net/http/httptest"
       "testing"
       "github.com/labstack/echo/v4"
    )
    var (
        g = Greetings{}
        s = Status{}
    )
    func TestGreetings(t *testing.T) {
       e := echo.New()
       req := httptest.NewRequest(http.MethodGet, "/", nil)
       rec := httptest.NewRecorder()
       c := e.NewContext(req, rec)
       HelloHandler(c)
       if rec.Code != 200 {
           t.Errorf("Expected status code is %d, but it was %d instead.", http.StatusOK, rec.Code)
       }
       json.NewDecoder(rec.Body).Decode(&g)
       if g.Greet != "Hello, World!" {
           t.Errorf("Expected value is \"Hello, World!\", but it was %s instead.", g.Greet)
       }
    }
    func TestStatus(t *testing.T) {
       e := echo.New()
       req := httptest.NewRequest(http.MethodGet, "/status", nil)
       rec := httptest.NewRecorder()
       c := e.NewContext(req, rec)
       StatusHandler(c)
       if rec.Code != 200 {
           t.Errorf("Expected status code is %d, but it was %d instead.", http.StatusOK, rec.Code)
       }
       json.NewDecoder(rec.Body).Decode(&s)
       if s.Status != "OK" {
           t.Errorf("Expected value is \"OK\", but it was %s instead.", s.Status)
       }
    }

    ```

1. Run tests

    ```bash
    go test ./...
    ```

## Containerization with Podman

We need to pack out an awesome app. To do that I decided to use
[Podman][2]. What Podman is? It is a daemonless container engine
for developing, managing, and running OCI Containers on
your Linux System.
Unfortunately, I prefer creating Dockerfile in Docker's way,
[Buildah][3] is not for me at least now.

### Create contianer

1. Create Dockerfile

    ```bash
    # Dockerfile
    FROM golang:alpine as builder
    RUN apk add --no-cache git gcc libc-dev
    WORKDIR /build/app
    # Get depedences
    COPY go.mod ./
    RUN go mod download
    # Run Testss
    COPY . ./
    RUN go test -v ./...
    # Build app
    RUN go build -o myapp
    FROM alpine
    COPY --from=builder /build/app/myapp ./myapp
    EXPOSE 1323
    CMD ["./myapp"]
    ```

1. Build an image

    ```bash
    podman build -t k8s-app .
    ```

1. Run image

    ```bash
    podman run -d -p 8080:1323 k8s-app:latest
    ```

1. Run basic `curl`'s test

    ```bash
    curl -s localhost:8080/status | jq .
    curl -s localhost:8080 | jq .
    ```

## Configure GCP

OK, we have working app now we need to create our Kubernetes cluster
for our deployment.

### Working with GCP

1. Auth into GCP

    ```bash
    gcloud auth login
    ```

1. Create a new project

    ```bash
    gcloud projects create [PROJECT_ID] --enable-cloud-apis

    # --enable-cloud-apis
    # enable cloudapis.googleapis.com during creation
    # example
    # gcloud projects create calcium-hobgoblins --enable-cloud-apis
    ```

1. Check existing projects

    ```bash
    gcloud projects list
    PROJECT_ID               NAME                     PROJECT_NUMBER
    calcium-hobgoblins       calcium-hobgoblins       xxxx
    ```

1. Set `gcloud` project

    ```bash
    gcloud config set project calcium-hobgoblins
    ```

1. Create a service account and add necessary permission

    ```bash
    gcloud iam service-accounts create calcium-hobgoblins-user \
    --description "Service user for GKE and GitHub Action" \
    --display-name "calcium-hobgoblins-user"

    gcloud projects add-iam-policy-binding calcium-hobgoblins --member \
    serviceAccount:calcium-hobgoblins-user@calcium-hobgoblins.iam.gserviceaccount.com \
    --role roles/compute.admin

    gcloud projects add-iam-policy-binding calcium-hobgoblins --member \
    serviceAccount:calcium-hobgoblins-user@calcium-hobgoblins.iam.gserviceaccount.com \
    --role roles/storage.admin

    gcloud projects add-iam-policy-binding creeping-hobgoblins --member \
    serviceAccount:calcium-hobgoblins-user@calcium-hobgoblins.iam.gserviceaccount.com \
    --role roles/container.admin

    gcloud projects add-iam-policy-binding calcium-hobgoblins --member \
    serviceAccount:calcium-hobgoblins-user@calcium-hobgoblins.iam.gserviceaccount.com \
    --role roles/iam.serviceAccountUser
    ```

1. List permission calcium-hobgoblins

    ```bash
    gcloud projects get-iam-policy calcium-hobgoblins  \
    --flatten="bindings[].members" \
    --format='table(bindings.role)' \
    --filter="bindings.members:calcium-hobgoblins-user@calcium-hobgoblins.iam.gserviceaccount.com"
    ```

## Push initial image to container registry

After setting up cloud project we have finally access
to the container registry.

### Auth and Push

1. Authenticate container registry

    ```bash
    gcloud auth activate-service-account \
    calcium-hobgoblins-user@calcium-hobgoblins.iam.gserviceaccount.com \
    --key-file=/home/kuba/.gcp/calcium-hobgoblins.json

    gcloud auth print-access-token | podman login \
    -u oauth2accesstoken \
    --password-stdin https://gcr.io
    ```

1. Push image into gcr.io

    ```bash
    podman push localhostk8s-app:latest docker://gcr.io/calcium-hobgoblins/k8s-app:0.0.1
    ```

## Provide Kubernetes Cluster

After setting up our GCP's project we need to provision out K8S cluster.

1. Create auth file

    ```bash
    mkdir -pv ~/.gcp
    cloud iam service-accounts keys create ~/.gcp/calcium-hobgoblins.json \
    --iam-account calcium-hobgoblins-user@calcium-hobgoblins.iam.gserviceaccount.com
    ```

1. Create a basic directory structure

    ```bash
    cd ../infra
    mkdir -pv DEV Module/GKE
    ```

1. Terraform directory structure looks like that:

    ```bash
    .
    ├── DEV
    │   ├── main.tf
    │   └── variables.tf
    └── Module
        └── GKE
            ├── main.tf
            └── variables.tf
    ```

1. Init Terrafrom

    ```bash
    cd DEV
    terraform init
    ```

1. Permission are important

    If we forget about `devstorage` out cluster will
    have a problem with pulling images...

    ```json
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
    ```

1. Terraform apply

    ```bash
    terraform apply -var="path=~/.gcp/calcium-hobgoblins.json"
    ```

1. Config `kubectl`

    ```bash
    export cls_name=my-gke-cluster
    export cls_zone=europe-west3-a
    gcloud container clusters list
    gcloud container clusters get-credentials cls_name --zone cls_zone
    kubectl get node
    ```

## Prepare Helm release

When we have a working cluster, we can prepare [helm][4] chart.
Also, it's a good time to install an ingress controller.

1. Init example helm chart

    ```bash
    cd ../..
    mkdir helm-chart
    cd helm-chart
    helm create k8s-app
    ```

1. Install Ingress with Helm(nginx)

    ```bash
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm install release ingress-nginx/ingress-nginx
    ```

## Add GitHub Action Pipeline

As an easy and great CI tool I decided to use GitHub Action again.

1. Add two files

    ```bash
    mkdir -pv .github/workflows
    touch .github/workflows/no-release.yml
    touch .github/workflows/release.yml
    ```

1. Add content to `no-release` file

    This file will execute every time when code will be pushed to the repository.

1. Add content to `release` file

    This file will execute only when pushed code will be tagged with `v*` expression.

1. Set GH Secrets

    `PROJECT_ID` - it's project - calcium-hobgoblins
    `GCP_SA_KEY` - auth file in base64

      ```bash
      cat ~/.gcp/calcium-hobgoblins.json | base64
      ```

1. Push some code into the repo

    ```bash
    git push origin master
    git push origin v.0.0.1
    ```

1. Check the status of pods

    ```bash
    kubectl get pods
    kubectl describe pod <pod-name>
    helm list release-k8s-app
    ```

## Summary

As you can see there is no source file for terraform and helm.
I decided for that move because the post is long enough even without it :) \
What else? I like Podman it just works without root permission on the host.
I still have some problems with Buildah, it's a bit uncomfortable for me.
Maybe in the future, or after another attempt. \
Setting K8S cluster is easy with
Terraform, but If we are planning production deployment all factors become
more complicated. \
Helm also looks like a nice tool in case a lot of similar
deployment, also tracking release history is a cool feature. Unfortunately, it's
not a magic tool and doesn't resolve all our CI/CD problems.

All code you can find [here][5]

[1]: https://github.com/labstack/echo
[2]: https://podman.io/
[3]: https://buildah.io/
[4]: https://helm.sh/
[5]: https://github.com/3sky/calcium-hobgoblins

