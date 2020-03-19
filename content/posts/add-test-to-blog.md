+++
draft = false
date = 2020-03-10T22:55:02Z
title = "Continuous integration/testing for static blog"
description = "GitHub page at the hard way"
slug = ""
tags = ["mdl", "GitHub Action", "grammarbot.io"]
categories = ["tutorials"]
externalLink = ""
series = ["GitHub Pages"]
+++

# Welcome

In a previous post, I created a static blog with a basic CD.
Now I need to add some CI. \
[Continuous Integration][1] (CI) is a development practice
that requires developers to integrate code into a shared
repository several times a day. Each check-in is then verified
by an automated build, allowing teams to detect problems early. \
Why it's mandatory? Because of my grammar errors, formatting errors,
and general errors. Nobody wants to have typos, broken markdown content
on the official blog page. At least I want to avoid it :)
So I decided to use [markdownlint][2],
project as my Markdown linter. Also, I need to integrate my content with some grammar
checker.

## Tools used in this episode

- markdownlint
- grammar checker
- GitHub Action

## markdownlint

[markdownlint][2] is a tool to check markdown
files and flag style issues.

### Why markdownlint

There is a lot of open-source tools
for checking syntax in the Markdown file.
This tool was first `Google Search`'s result.
Documentation looks clean and understandable.
In case of any problem, I can just change a tool.

### Let's code - markdownlint

1. Installation of `mdl`
    I would like to add linter to automatic pipeline,
    so changes in `.github/workflows/main.yml` are mandatory.

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
        - name: Install ruby-dev # Start test
          run: sudo ap-get install ruby-dev
        - name: Install rake and bundler
          run: sudo gem install rake bundler
        - name: Run tests
          run: mdl content/* # End of test
        - name: Run deploy.sh
          env:
            GH_TOKEN: ${{ secrets.GH_TOKEN }}
          run: sh ./deploy.sh
    ```

### Summary - markdownlint

That again was easy, isn't it? Isn't :) Usage of this
linter requires a lot of work from my side, especially
with [MD013][3] error type. Adding fixes and tracking
all `space` errors was an arduous process -
every single error can break my build, but finally,
I get well-formatted, correct Markdown files.

## grammarbot

[grammarbot.io][3] Grammar Bot is a simple API -
just send us your text, then the API returns
a list of potential grammar and spelling errors
that we find. Please note that only English is
supported at the moment (en-US or en-GB).

### Why grammarbot

There is not much open-source tools/API
for checking grammar in file. Well-know and solid product -
[grammarly][5], don't expose their API to the public.
So I find the `grammarbot.io`. As in the case with
`markdownlint` this tool was
first `Google Search`'s result.
There are a lot of ready to use
bot, but I decided that I want to write [my own][6]
just become I want CLI tool.
Documentation also looks clean and understandable.

### Let's code - grammarbot

1. Basic usage

    ```bash
    curl -s -X POST \
    -d "api_key=XYZ" \
    -d "language=en-US" \
    -d "text=I can't remember how to go their" \
    "http://api.grammarbot.io/v2/check" | jq .

    # -s for usage with jq
    # jq = small tool for JSON formatting
    # worth to check
    # text = param is flexable put there
    # evertything
    ```

1. Retrieve a personal token

    If you want to use grammarbot you need a personal token.
    It's free, but with some limitations. In my opinion, the free plan will
    be enough.

1. Remove ` ``` `

    The biggest problem with this API and my tool was
    scanning section inside ` ``` `.
    Grammarbot has a problem with technical
    topics and tools names. So I decided to remove this section with `sed`.

    ```bash
    sed '/```/,/```/d' <filename>.md > tmp/<filename>.md

    # sed by default print result to stdout
    # so I need to redirect it to new file
    # example
    # sed '/```/,/```/d' how-to-gp-1.md > tmp/how-to-gp-1.md
    ```

1. Implementation

    Now I have ready resources and tools.
    That's time to make from it real a pipeline.
    So final GitHub Action manifest looks like that.

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
          - name: Install ruby-dev
            run: sudo apt-get install ruby-dev
          - name: Install depedances for mdl
            run: |
              sudo gem install rake bundler mdl
              sudo gem update --system 3.0.6
          - name: Setup GCP
            # This section will be discussed in another post
            uses: GoogleCloudPlatform/github-actions/setup-gcloud@master
            with:
              version: '281.0.0'
              service_account_email: ${{ secrets.GCP_SA_EMAIL }}
              service_account_key: ${{ secrets.GCP_SA_KEY }}
              export_default_credentials: true
          - name: Get grammary-cli
            run: |
              gsutil cp gs://grammarybot-cli/grammary-cli .
              chmod +x grammary-cli
            # This section will be descused in another post
          - name: Run tests
            run: |
              mkdir -p tmp
              for i in $(ls content/posts/);
                do sed '/```/,/```/d' content/posts/$i > tmp/$i;
              done
              mdl content/*
              for i in $(ls tmp/);
                do ./grammary-cli -token ${{ secrets.GB_TOKEN }} -path tmp/$i;
              done
          - name: Run deploy.sh
            env:
              GH_TOKEN: ${{ secrets.GH_TOKEN }}
            run: sh ./deploy.sh
      ```

There are two Bash's loops:

  ```bash
  for i in $(ls content/posts/);
    do sed '/```/,/```/d' content/posts/$i > tmp/$i;
  done

  # get names of all post from content/posts/
  # remove ``` and put copies inside tmp dir
  ```

  ```bash
  for i in $(ls tmp/);
    do ./grammary-cli -token ${{ secrets.GB_TOKEN }} -path tmp/$i;
  done

  # get names of all temporary post from tmp
  # execute grammary-cli with filename as param
  ```

### Summary - grammarbot

Brammarbot is a useful tool with good API.
Unfortunately, it's not the best solution for scanning.
Especially for text like my, a lot of strange names
like Nginx, etc. Also, it's markdown so formating is unusual.
So I get a lot of information about possible typos, grammar
errors, even without a section in ` ``` `. Related with that
and quantity of posts I will get a lot of error in my build log.
At this point, I'll leave it as It is, but in future maybe I will
be forced to disable this solution. \
From another side, I learn a lot about possible problems,
GH Action and GCP. The goal has been achieved :)

[1]: https://www.thoughtworks.com/continuous-integration
[2]: https://github.com/markdownlint/markdownlint
[3]: https://github.com/markdownlint/markdownlint/blob/master/docs/RULES.md#md013---line-length
[4]: https://www.grammarbot.io/
[5]: https://app.grammarly.com/
[6]: https://3sky.github.io/posts/grammary-bot/