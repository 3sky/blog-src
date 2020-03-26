+++
draft = false
date = 2020-03-26T20:30:02Z
title = "Build your onw GitHub Action"
description = "Sometimes I need more custom solution or more elegant"
slug = ""
tags = ["GitHub Action", "Docker", "Bash"]
categories = ["tutorials"]
externalLink = ""
series = ["GitHub Action"]
+++

# Welcome

Sometimes age I started using GitHub Actions. It's fast, simple, easy
to configure. There isn't a lot of fancy configuration options like for
example in Jenkins, but if someone has neat, container-based pipelines,
Actions are worth considering CI/CD system. But what this `Actions` really mean?
`Actions` are mostly community written code that is responsible for
activities like, pushing image, sending the notification, checking source code.
There are two options for developers: Bash and JavaScript.
Unfortunately, I have two operations which haven't ready Action. So I decided
to write my Action and support the community. At least I hope it will be
helpful for someone.

## Tools used in this episode

- Gitub Action
- Docker
- Bash (I can't into JavaScript)

## Problem no.1

I would like to check `/status` endpoint of my application and
validate JSON output. It's useful when I need a check for example deployment result.
That's a really small problem and a great opportunity to learn `GitHub Action` ecosystem.

### Problem no.1 current solution

```yaml {linenos=table}
- name: Check stg
  run: if [[ ! $(curl -s $URL/status | grep ok) ]]; then exit 1; fi
 ```

It's a clean and ordinary solution, but customization it's hard in case
of more complicated output. It also requires some Bash knowledge and manual
changes.

### Solution no.1

1. Create new repo with License file (`MIT` is 'okay`)

1. Clone repo to the workstation.

    ```console
    git clone git@github.com:3sky/glowing-spoon.git
    cd glowing-spoon
    ```

1. Define `action.yaml`

    It's the main Action file. Here is the place to define
    stuff like input/output, name, description, parameters
    initial configuration etc.

    ```yaml  {linenos=table}
    # action.yml
    name: 'Endpoint check'
    author: '3sky'
    description: 'Wrapper on wget and jq for make response validation'
    branding:
      icon: 'check-square'
      color: 'white'
    inputs:
      hostname:
        description: 'Hostname to check'
        required: true
        default: 'my-json-server.typicode.com'
      path:
        description: 'Path of endpoint'
        required: true
        default: '/typicode/demo/db'
      filter:
        description: 'jq filter'
        required: true
        default: '.profile.name'
      expected:
        description: 'Expected value from request'
        required: true
        default: 'typicode'
      unsecure:
        description: 'Skip certification validation'
        required: false
        default: false
    outputs:
      result:
        description: 'Result of check'
    runs:
      using: 'docker'
      image: 'Dockerfile'
      args:
        - ${{ inputs.hostname }}
        - ${{ inputs.path }}
        - ${{ inputs.filter }}
        - ${{ inputs.expected }}
        - ${{ inputs.unsecure }}
    ```

1. Create `entrypoint.sh`

    ```bash {linenos=table}
    # entrypoint.sh
    #!/bin/sh -l

    # Define variables
    # Get params from action.yaml
    HOSTNAME=$1
    PATH=$2
    FILTER=$3
    EXPECTED=$4
    UNSECURE=$5

    URL="https://${HOSTNAME}${PATH}"

    if $UNSECURE; then
        result=$(/usr/bin/wget --no-check-certificate -qO- "$URL" | /usr/bin/jq -r "$FILTER")
    else
        result=$(/usr/bin/wget -qO- "$URL" | /usr/bin/jq -r "$FILTER")
    fi

    if [ "$EXPECTED" != "$result" ]; then
        echo "Expected: ${EXPECTED} ; Get: ${result}"
        exit 1;
    fi

     # declare output
    echo "::set-output name=result::$result"
    ```

1. Create Dockerfile

    ```Dockerfile {linenos=table}
    # Dockerfile
    FROM alpine:3.10

    # I need to install only wget and jq
    RUN apk update && apk add wget jq && rm -rf /var/cache/apk/*

    # Copies your code file from your action
    # repository to the filesystem path `/` of the container
    COPY entrypoint.sh /entrypoint.sh

    # Code file to execute when the docker container starts up (`entrypoint.sh`)
    ENTRYPOINT ["sh", "/entrypoint.sh"]
    ```

1. Don't forget about `README.md`

    ```bash
    echo "Hello World" > README.md
    ## Hehhe :)
    ```

1. Now we need to define `main.yaml`

    I used `main.yaml` as a test job for my Action. To achieve that
    I declared [public JSON endpoint][1], and some
    basic variables should finish without errors.

    ```yaml {linenos=table}
    # .github/workflows/main.yaml
    on: [push]

    jobs:
      hello_world_job:
        runs-on: ubuntu-latest
        name: Check my-json-server
        steps:
        - name: Check my-json-server
          id: check-it
          uses: 3sky/glowing-spoon@v0.0.1
          with:
            hostname: 'my-json-server.typicode.com'
            path: '/typicode/demo/db'
            filter: '.profile.name'
            expected: 'typicode'
        - name: Get the output
          run: echo "Resutl is ${{ steps.check-it.outputs.result }}"
    ```

    Note that v0.0.1 it's tag from 3sky/glowing-spoon repository.
    It's quite important :)

1. Add, commit, tag, and push

    ```bash
    git add -A
    git commit -m 'initial commit'
    git tag -a -m 'first tag' v0.0.1
    git push origin v0.0.1
    git push origin master
    ```

1. Now we should get a nice, green mark in the `Action` tab.

### Usage of glowing-spoon

1. Lets use [upgraded-octo-winner][2]

    ```yaml {linenos=table}
    # 3sky/upgraded-octo-winner/.github/workflows/master.yml
    # from:
    - run: if [[ ! $(curl -s $PROD_URL/status | grep ok) ]]; then exit 1; fi

    # into:
    - name: Check PROD
      uses: 3sky/glowing-spoon@v0.0.1
      with:
        hostname: "$PROD_URL"
        path: 'status'
        filter: '.status'
        expected: 'ok'
    ```

## Problem no.2

I would like to deploy, update and delete Cloud Run
service without long shell script. Also, I try to
make my GCP setup which could be easier to use and faster.

### Problem no.2 current solution

```yaml {linenos=table}
- name: Setup GCP
  uses: GoogleCloudPlatform/github-actions/setup-gcloud@master
  with:
    version: '281.0.0'
    service_account_email: ${{ secrets.GCP_SA_EMAIL }}
    service_account_key: ${{ secrets.GCP_SA_KEY }}
    export_default_credentials: true
  - name: update prod
    run: gcloud run deploy $PROD_SERVICE --project ${{ secrets.PROJECT_ID }}  --platform managed --region europe-west1 --image gcr.io/${{ secrets.PROJECT_ID }}/$APP_NAME:${{ github.sha }}
 ```

It's a long, ugly and time-consuming solution. Shell scripts are
long and susceptible to manual error.
Especially when we talk about line breaks inside YAML.

### Solution no.2

1. Create new repo with License file (`MIT` is 'okay`)

1. Clone repo to the workstation.

    ```console
    git clone git@github.com:3sky/furry-octo-parakeet.git
    cd furry-octo-parakeet
    ```

1. Define `action.yaml`

    ```yaml  {linenos=table}
    # action.yml
    name: 'Cloud Run helper'
    author: '3sky'
    description: 'Deploy, update or delete your Cloud Run service'
    branding:
      icon: 'terminal'
      color: 'green'
    inputs:
      auth_file:
        description: 'Auth file encoded with base64'
        required: true
        default: ''
      action:
        description: 'Action to perform run/update/delete'
        required: true
        default: 'update'
      name:
        description: 'Name of service'
        required: true
        default: 'My-service'
      region:
        description: 'Region for deployment'
        required: false
        default: 'europe-west1'
      allow:
        description: 'Allow unauthenticated traffic'
        required: false
        default: false
      port:
        description: 'Port to expose'
        required: false
        default: 80
      image:
        description: 'Image name'
        required: true
        default: 'gcr.io/cloud-marketplace/google/nginx1:latest'
    runs:
      using: 'docker'
      image: 'Dockerfile'
      args:
        - ${{ inputs.auth_file }}
        - ${{ inputs.action }}
        - ${{ inputs.name }}
        - ${{ inputs.region }}
        - ${{ inputs.port }}
        - ${{ inputs.image }}
        - ${{ inputs.allow }}
    ```

1. Create `entrypoint.sh`

    ```bash {linenos=table}
    #!/bin/sh -l

    # Define variables
    AUTH_FILE=$1
    ACTION_TYPE=$2
    NAME=$3
    REGION=$4
    PORT=$5
    IMAGE=$6
    ALLOW=$7
    PROJECT_ID=$8

    # Generate random filename
    FILENAME=$(mktemp)

    # Encode GH secret
    echo "$AUTH_FILE" | base64 -d > "$FILENAME"
    chmod 600 "$FILENAME"

    # Get project_id and EMAIL
    PROJECT_ID=$(jq -r .project_id "$FILENAME")
    EMAIL=$(jq -r .client_email "$FILENAME")

    # Activate account
    if gcloud auth activate-service-account "$EMAIL" --key-file="$FILENAME" ; then
        echo "Authentication successful"
    else
        echo "Authentication faild"
        exit 1;
    fi

    # Set project
    if gcloud config set project "$PROJECT_ID" ; then
        echo "Setting project successful"
    else
        echo "Setting project failed"
        exit 1;
    fi

    if [ "$ACTION_TYPE" = "run" ] || [ "$ACTION_TYPE" = "update" ] || [ "$ACTION_TYPE" = "delete" ]; then
        echo "Choose $ACTION_TYPE as action type"
    else
        echo "Wrong action type, Possible solution run|update|delete"
        exit 1;
    fi

    if [ "$ACTION_TYPE" = "run" ]; then
        if $ALLOW; then
            gcloud run deploy "$NAME" \
            --platform managed \
            --allow-unauthenticated \
            --region "$REGION" \
            --port "$PORT" \
            --image "$IMAGE"
        else
            gcloud run deploy "$NAME" \
            --platform managed \
            --region "$REGION" \
            --port "$PORT" \
            --image "$IMAGE"
        fi
    elif [ "$ACTION_TYPE" = "update" ]; then
        gcloud run deploy "$NAME" \
        --platform managed \
        --region "$REGION" \
        --image "$IMAGE"
    elif [ "$ACTION_TYPE" = "delete" ]; then
        gcloud run services delete "$NAME" \
        --platform managed \
        --region "$REGION" \
        --quiet
    fi
    ```

1. Create Dockerfile

    ```Dockerfile {linenos=table}
    # Container image with gcloud installed
    FROM google/cloud-sdk:alpine

    RUN apk --update add jq
    # Copies your code file from your
    # action repository to the filesystem path `/` of the container
    COPY entrypoint.sh /entrypoint.sh

    # Code file to execute when the docker container starts up (`entrypoint.sh`)
    ENTRYPOINT ["sh", "/entrypoint.sh"]
    ```

1. Don't forget about `README.md`

    ```bash
    echo "Hello World" > README.md
    ## Hehhe vol.2 :)
    ```

1. Now we need to define `main.yaml`

    I used `main.yaml` as a test job for my Action again. To achieve that
    I run a new service, then update base image, at the end delete service.

    ```yaml {linenos=table}
    on: [push]

    jobs:
      hello_world_job:
        runs-on: ubuntu-latest
        name: Mega deploy
        steps:
        - name: deploy app
          uses: 3sky/furry-octo-parakeet@master
          with:
            auth_file: ${{ secrets.gcp_sa_key }}
            action: 'run'
            name: 'basic-nginx'
            region: 'europe-west1'
            allow: true
            image: 'gcr.io/cloud-marketplace/google/nginx1:latest'
        - name: update app
          uses: 3sky/furry-octo-parakeet@master
          with:
            auth_file: ${{ secrets.gcp_sa_key }}
            action: 'update'
            name: 'basic-nginx'
            region: 'europe-west1'
            image: 'gcr.io/cloud-marketplace/google/nginx:1.15'
        - name: destroy app
          uses: 3sky/furry-octo-parakeet@master
          with:
            auth_file: ${{ secrets.gcp_sa_key }}
            action: 'delete'
            name: 'basic-nginx'
            region: 'europe-west1'
    ```

    Note that I decrease lines of code, and make login a bit simpler.

1. Add, commit, tag, and push

    ```bash
    git add -A
    git commit -m 'initial commit'
    git tag -a -m 'first tag' v0.0.1
    git push origin v0.0.1
    git push origin master
    ```

### Usage of furry-octo-parakeet

1. Lets use [upgraded-octo-winner][2]

    ```yaml {linenos=table}
    # 3sky/upgraded-octo-winner/.github/workflows/master.yml
    # from:
    - name: Setup GCP
      uses: GoogleCloudPlatform/github-actions/setup-gcloud@master
      with:
        version: '281.0.0'
        service_account_email: ${{ secrets.GCP_SA_EMAIL }}
        service_account_key: ${{ secrets.GCP_SA_KEY }}
        export_default_credentials: true
    - name: update prod
      run: gcloud run deploy $PROD_SERVICE --project ${{ secrets.PROJECT_ID }}  --platform managed --region europe-west1 --image gcr.io/${{ secrets.PROJECT_ID }}/$APP_NAME:${{ github.sha }}

    # into:
    - name: deploy app
      uses: 3sky/furry-octo-parakeet@master
      with:
        auth_file: ${{ secrets.GCP_SA_KEY }}
        action: 'run'
        name: "$PROD_SERVICE"
        region: 'europe-west1'
        allow: true
        image: "gcr.io/{{ secrets.PROJECT_ID }}/$APP_NAME:${{ github.sha }}"
    ```

## Summary

That's all. To be honest I'm proud of this `Cloud Run helper`.
That's an easy script, but just `do the stuff`.
Writing custom Actions was an enjoyable adventure.
It takes some time, however, it's quarantine time.
That's another not very useful skill, but working with Bash
scripts is always an adventure. Fortunately, I
had a [friend][3] who help me with that.

[1]: https://my-json-server.typicode.com/
[2]: https://github.com/3sky/upgraded-octo-winner
[3]: https://www.shellcheck.net/