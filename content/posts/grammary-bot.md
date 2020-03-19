+++
draft = false
date = 2020-03-10T23:55:02Z
title = "Build grammarbot client in Go"
description = "GitHub page at the hard way"
slug = ""
tags = ["Go", "GitHub Action", "GCP", "Telegram"]
categories = ["tutorials", "programming"]
externalLink = ""
series = ["GitHub Pages"]
+++

# Welcome

While working with [grammarbot][1], I decided
to create my own command-line tool/client for working with API.
As a language, I have chosen [Golang][2]. After that, I have added
GitHub Action and gsutil. Also, I have configured Telegrams bot
for notification purpose. Sounds like fun? For me definitely.
So stop writing, and `show me your code`.

## Tools used in this episode

- Go
- grammarbot.io API
- GitHub Action
- GCP
- Telegram

## Go

[Go][2] is an open-source programming language that makes
it easy to build simple, reliable, and efficient software.

### Why Go

It's open-source. It's fast, pleasant and readable language.
Static compilation allows me to ship apps without problems.
I just like Go.

### Let's code - Go

1. Install Go

    Everything is [here][3]. I think there is no
    need to provide additional information from my side.

1. Setup a new project

    ```bash
    # $Projects = working dir
    # for me /home/kuba/Desktop/Projekty/
    cd $Projects
    mkdir grammarybot

    go mod init github.com/3sky/grammarybot-cli
    # I like VSCode
    code .
    ```

1. Create `main.go`

    ```go
    package main

    // only standard libs
    import (
        "encoding/json"
        "errors"
        "flag"
        "fmt"
        "io/ioutil"
        "net/http"
        "os"
        "time"
    )

    //FreePlanLimit limit of chrackter in free plan
    //grammarbot limit is 50000 char
    const FreePlanLimit = 50000

    type stop struct {
        error
    }

    func main() {

        // Constants variables - I like CAPS style
        LANGAUGE := "en-US"
        URL := "http://api.grammarbot.io/v2/check"

        // CLI flag declatarion
        botToken := flag.String("token", "XYZ", "Grammarbot token")
        pathToFile := flag.String("path", "", "Path to file")
        flag.Parse()

        //loading file to check
        text, err := LoadFile(*pathToFile)
        if err != nil {
            fmt.Println(err)
        }

        // usage retry function becouse of
        // Internall Server Error
        err = retry(3, time.Second*3, func() error {
            return CheckText(LANGAUGE, URL, *botToken, text)
        })
        if err != nil {
            fmt.Printf("checkText error %v", err)
        }

    }

    //LoadFile load file and check against planlimit
    func LoadFile(path string) (string, error) {

        pwd, err := os.Getwd()
        defer func() {
            if err != nil {
                fmt.Fprintf(os.Stderr, "Fatal panic: %v", err)
                os.Exit(1)
            }
        }()

        content, err := ioutil.ReadFile(pwd + "/" + path)
        defer func() {
            if err != nil {
                fmt.Fprintf(os.Stderr, "Fatal panic: %v", err)
                os.Exit(1)
            }
        }()

        text := string(content)
        defer func() {
            if len(text) > FreePlanLimit {
                fmt.Fprintf(os.Stderr, "Test is to long: %d", len(text))
                os.Exit(1)
            }
        }()

        return text, nil
    }

    //CheckText send text to grammary
    func CheckText(lang, url, token, text string) error {

        var client http.Client
        var data ResponseStruct
        req, err := http.NewRequest("POST", url, nil)
        if err != nil {
            return err
        }
        q := req.URL.Query()
        q.Add("api_key", token)
        q.Add("language", lang)
        q.Add("text", text)
        req.URL.RawQuery = q.Encode()

        resp, err := client.Do(req)
        if err != nil {
            return err
        }

        if resp.StatusCode != 200 {
            return errors.New("Internal GrammaryBot Error")
        }

        err = json.NewDecoder(resp.Body).Decode(&data)
        if err != nil {
            return err
        }

        x, err := json.MarshalIndent(data.Matches, "", "\t")
        if err != nil {
            return err
        }

        // empty len((string(x)) == 2
        if len(string(x)) <= 2 {
            fmt.Println("Text is OK")
        } else {
            fmt.Println(string(x))
        }

        return nil
    }

    // to avoid Internal Server Error from GrammaryBot side
    func retry(attempts int, sleep time.Duration, fn func() error) error {

        if err := fn(); err != nil {
            if s, ok := err.(stop); ok {
                return s.error
            }

            if attempts--; attempts > 0 {
                fmt.Printf("Take a try: %d", attempts)
                time.Sleep(sleep)
                return retry(attempts, 2*sleep, fn)
            }
            return err
        }
        return nil
    }
    ```

1. Define `structs.go` in a separate file
    Nothing special file is in [repo][4]

1. Define some basic tests `main_test.go`

    ```go
    package main

    import (
        "strings"
        "testing"
    )

    func TestCheckText(t *testing.T) {
        LANGAUGE := "en-US"
        URL := "http://api.grammarbot.io/v2/check"
        botToken := "XYZ"
        text := "I can't remember how to go their"

        err := CheckText(LANGAUGE, URL, botToken, text)
        if err != nil {
            t.Errorf("Error with CheckText funtion")
        }
    }

    func TestLoadFile(t *testing.T) {

        PATH := "go.mod"
        str, err := LoadFile(PATH)
        if err != nil {
            t.Errorf("Error with TestLoadFile funtion")
        }
        if !(strings.Contains(str, "github.com/3sky/grammarybot-cli")) {
            t.Errorf("Error with TestLoadFile, string is wrong")
        }
    }
    ```

1. Run test

    ```bash
    ➜  grammarybot go test ./...
    ok      github.com/3sky/grammarybot-cli 0.914s
    ➜  grammarybot
    ```

1. OK, now build app make some real test

    ```bash
    go build -o grammary-cli .
    ```

    Then:

    ```bash
    ./grammary-cli -token XYZ -path tmp/how-to-gp-1.md
    ```

    And works, but the output is very long so I passed only a part:

    ```bash
    ...
      {
            "message": "Possible typo: you repeated a whitespace",
            "shortMessage": "",
            "replacements": [
                    {
                            "value": " "
                    }
            ],
            "offset": 3975,
            "length": 4,
            "context": {
                    "text": "...y the Terraform-managed infrastructure
                          `WARNING` - At the end of learning     s...",
                    "offset": 43,
                    "length": 4
            },
            "sentence": "`WARNING` - At the end of learning\n
                        session destroy unused infrastructure - it's cheaper",
            "type": {
                    "typeName": "Other"
            },
            "rule": {
                    "id": "WHITESPACE_RULE",
                    "description": "Whitespace repetition (bad formatting)",
                    "issueType": "whitespace",
                    "category": {
                            "id": "TYPOGRAPHY",
                            "name": "Typography"
                    }
            }
        },
    ...
    ```

### Summary - Go

That was a nice phase. I very enjoy writing Go code.
Maybe I'm not the best coder, but the tool works ;)
I define some flags, basic tests, and the application to do what should do.
Tool is fast, `500` error type ready and portable.
Token is provided as a parameter, so there is no hardcodes.

## GitHub Action

### Let's code - GitHub Action

1. Create `.github/workflows/main.yml`

    That will be the pipeline for the `deploy` app to Google Storage.
    So the sceleton will be:

    ```yaml
    on: [push]
    name: grammary-cli
    jobs:
    build:
        runs-on: ubuntu-latest
        steps:
        - name: Install Go
          uses: actions/setup-go@v1
          with:
            go-version: 1.14.x
        - name: Setup GCP # Install GCP stuff
        - name: verify gsutil installation # Verify instalation
        - name: Checkout code
          uses: actions/checkout@v2
        - name: Test
          run: go test ./... -v
        - name: Build
          run: go build -o grammary-cli
        - name: Deploy  # Deploy binary
        - name: notify # Send notification
    ```

## Google Cloud Platform

### Let's code - GCP

1. Install tools on runner

    In GitHub Action we have ready `actions` avalaible in [market][5].
    So I decided to use one.

    ```yaml
    - name: Setup GCP
      uses: GoogleCloudPlatform/github-actions/setup-gcloud@master
      with:
        version: '281.0.0'
        service_account_email: ${{ secrets.GCP_SA_EMAIL }}
        service_account_key: ${{ secrets.GCP_SA_KEY }}
        export_default_credentials: true
    - name: verify gsutil instalation
      run: gsutil ls -p tokyo-baton-256120
    ```

    That snipped contains two secrets `secrets.GCP_SA_KEY`
    and `secrets.GCP_SA_EMAIL`. \
    To get this value I need to create IAM role for
    `Google Storage Access`. I highly recommend this [docs][6].
    Then when I get `auth.json` I can go forward. \

    `GCP_SA_EMAIL` - `client_email` from  `auth.json` \
    `GCP_SA_KEY` it's whole encoded file

    ```bash
    cat auth.json | base64
    ```

## Gsutil

### Let's code - Gsutil

1. Deploy binary to Storage

    ```yaml
    - name: Deploy
      run: |
        ls -lR
        gsutil cp grammary-cli gs://grammarybot-cli
    ```

    `gsutil` is very similar to `sftp` command. So
    syntax is easy

    ```bash
    gsutil cp [OPTION]... src_url dst_url
    gsutil cp [OPTION]... src_url... dst_url
    gsutil cp [OPTION]... -I dst_url
    ```

## Telegram

### Let's code - Telegram

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

    1. `TELEGRAM_TO` is field `chat.id`

1. Configure notification

    I would like to get some notification after the build.
    Telegram is a nice tool, and there is already created [GH Action][7].

    ```yaml
    - name: test telegram notification
      uses: appleboy/telegram-action@master
      with:
        to: ${{ secrets.TELEGRAM_TO }}
        token: ${{ secrets.TELEGRAM_TOKEN }}
        message: |
          Hello my Master
          Build number ${{ github.run_number }}
          of ${{ github.repository }} is complete ;)
    ```

    That snipped contains two secrets `secrets.TELEGRAM_TO`
    and `secrets.TELEGRAM_TOKEN`.
    Again I can recommend this [docs][8].
    But I received this value in the previous section. \

    There are also two context variable `github.run_number` and `github.repository`.
    And again [docs][9] are more than enough.

## Final main.yml

```yaml
on: [push]
name: grammary-cli
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Install Go
      uses: actions/setup-go@v1
      with:
        go-version: 1.14.x
    - name: Setup GCP
      uses: GoogleCloudPlatform/github-actions/setup-gcloud@master
      with:
        version: '281.0.0'
        service_account_email: ${{ secrets.GCP_SA_EMAIL }}
        service_account_key: ${{ secrets.GCP_SA_KEY }}
        export_default_credentials: true
    - name: verify gsutil instalation
      run: gsutil ls -p tokyo-baton-256120
    - name: Checkout code
      uses: actions/checkout@v2
    - name: Test
      run: go test ./... -v
    - name: Build
      run: go build -o grammary-cli
    - name: Deploy
      run: |
        ls -lR
        gsutil cp grammary-cli gs://grammarybot-cli
    - name: test telegram notification
      uses: appleboy/telegram-action@master
      with:
        to: ${{ secrets.TELEGRAM_TO }}
        token: ${{ secrets.TELEGRAM_TOKEN }}
        message: |
          Hello my Master
          Build number ${{ github.run_number }}
          of ${{ github.repository }} is complete ;)
```

## Push all code

1. Add repo

    ```bash
    git init
    git remote add origin git@github.com:<user>/<reponame>.git

    # Example
    # git remote add origin git@github.com:3sky/grammarybot-cli.git
    ```

1. Commit changes and push it

    ```bash
    git add -A
    git commit -m 'init commmit'
    git push origin master
    ```

## Final

That was a long journey, but it's working at least
in my [environment][10] :) Whole post contains useful information
about small tool's delivery pipeline. It was fun to work with all
these products and resolving different problems. GH Action is still awesome,
Telegram bots are easy to setup when botFather works. Because it's not obvious,
sometimes is just overloaded. Finding a free username is also hard.
For me, very helpful was the name generator based on food and job titles.
Google Cloud Platform delivers a nice IAM policy, so there wasn't a problem with
configuration. Gsutil it's just a command-line tool, so it works as should.
To summarize programming and codding is easier than writing human-readable blog
posts :)

[1]: https://www.grammarbot.io/
[2]: https://golang.org/
[3]: https://golang.org/doc/install
[4]: https://github.com/3sky/grammarybot-cli/blob/master/structs.go
[5]: https://github.com/marketplace?type=actions
[6]: https://cloud.google.com/iam/docs/service-accounts
[7]: https://github.com/appleboy/telegram-action
[8]: https://core.telegram.org/bots/api
[9]: https://help.github.com/en/actions/reference/context-and-expression-syntax-for-github-actions#github-context
[10]: https://github.com/3sky/grammarybot-cli