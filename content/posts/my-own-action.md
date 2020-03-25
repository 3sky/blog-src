+++
draft = true
date = 2020-03-25T21:55:02Z
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
example in Jenkins, but if someone have neat, container-based pipelines, 
Actions are worth to consider CI/CD system. But what this `Actions` really means?
`Actions` are mostly community written code which is responsible for 
activities like, pushing image, sending notification, checking source code.
There are two options for developers: Bash and JavaScript. 
Unfortunetlly, I have two operation which haven't ready Action. So I decided
to write my own Action and support the community. At least I hope it will be 
helpful for someone. 

# Tools used in this episode

- Gitub Action
- Docker
- Bash (I can't into JavaScript)

## Problem no.1 

I would like to check `/status` endpoint of my application and 
validate JSON output. It's useful when I need check for example deployment result.
That's really small problem and great opportunity to learn `GitHup Action` ecosystem. 

### Current Problem no.1 solution

```yaml {linenos=table}
- name: Check stg
  run: if [[ ! $(curl -s $URL/status | grep ok) ]]; then exit 1; fi
 ```

It's clean and ordinary solution, but customization it's hard in case
of more complicated output. Also require some Bash knowalge, and manual
changes.
 
### Solution n0.1

1. Create new repo with License file

1. Clone repo to workstation.

    ```console
    git clone git@github.com:3sky/glowing-spoon.git
    cd glowing-spoon
    ```

1. Create `entrypoint.sh`

    ```bash
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
    # Container image that runs your code
	FROM alpine:3.10
    
    # i need to install only wget and jq
	RUN apk update && apk add wget jq && rm -rf /var/cache/apk/*

	# Copies your code file from your action repository to the filesystem path `/` of the container
	COPY entrypoint.sh /entrypoint.sh

	# Code file to execute when the docker container starts up (`entrypoint.sh`)
	ENTRYPOINT ["sh", "/entrypoint.sh"]
	```

1. Define `action.yaml`

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

1. Don't forget about `README.md`

    ```bash
	echo "Hello World" > README.md
    ```

1. Now we need to define `main.yaml`

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

1. Add, commmit, tag, and push

	```bash
	git add -A
	git commit -m 'initial commit'
    git tag -a -m 'first tag' v0.0.1
    git push origin v0.0.1
	git push origin master
	```

1. Now we should get nice, green mark in `Action` tab.


[1]: https://pages.github.com/
[2]: https://themes.gohugo.io/
[3]: https://www.terraform.io/
[4]: https://console.cloud.google.com/apis/credentials/serviceaccountkey
[5]: https://gohugo.io/
[6]: https://www.nginx.com/
