+++
draft = true
date = 2020-03-09T09:55:02Z
title = "How to use GitHub Pages #1"
description = "GitHub page at the hard way"
slug = ""
tags = ["mdl", "GitHub Action"]
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
on the official blog page. At least I want to avoid it :) So I decided to use [markdownlint][2],
project as my Markdown linter. Also, I need to integrate my content with some grammar
checker.

## Tools used in this episode

- markdownlint
- grammar checker

## markdownlint

[markdownlint][2] is a tool to check markdown
files and flag style issues.

### Why markdownlint

There is a lot of open-source tools
for checking syntax in the Markdown file.
This tool was first `Google Search`'s result.
Documentation looks clean and understandable.
In case of any problem, I can just change a tool.

#### Let's code - markdownlint

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
          # Start test
        - name: Install ruby-dev
          run: sudo ap-get install ruby-dev
        - name: Install rake and bundler
          run: sudo gem install rake bundler
        - name: Run tests
          run: mdl content/*
          # End of test
        - name: Run deploy.sh
          env:
            GH_TOKEN: ${{ secrets.GH_TOKEN }}
          run: sh ./deploy.sh
    ```

#### Summary - markdownlint

That again was easy, isn't it? Isn't :) Usage of this
linter requires a lot of work from my side, especially
with [MD013][3] error type. Adding fixes and tracking
all `space` errors was an arduous process -
every single error can break my build, but finally,
I get well-formatted, correct Markdown files.

[1]: https://www.thoughtworks.com/continuous-integration
[2]: https://github.com/markdownlint/markdownlint
[3]: https://github.com/markdownlint/markdownlint/blob/master/docs/RULES.md#md013---line-length