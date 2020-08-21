+++
draft = false
date = 2020-04-10T20:30:02Z
title = "Why I need VIM?"
description = "Short story about legendary tool"
slug = ""
tags = ["IDE", "Vim"]
categories = ["Text"]
externalLink = ""
series = ["Tips"]
+++

# Welcome

During quarantine, I expected to have more time. Unfortunately
I fall in love with making Neapolitan Style pizza, sourdough based
bread, and homemade tortillas. However, also I decided to master VIM.
But why? I would like to explain it in a few words.

## What's is VIM

[Vim][1] is a highly configurable text editor built to enable efficient
text editing. It is an improved version of the vi editor distributed
with most UNIX systems. Vim is often called a "programmer's editor,"
and so useful for programming that many consider it an entire IDE.
It's not just for programmers, though. Vim is perfect for all kinds
of text editing, from composing an email to editing configuration files.
Despite what the above comic suggests, Vim can be configured to
work in a very simple (Notepad-like) way, called evim or Easy Vim.

### So why I decided to use it

#### Vim is almost on every modern Linux system

We can find Vim on MacOS, most of Linux distro as Ubuntu, Debian, Fedora.
It's a default text editor for BSD. So it's almost everywhere.

#### Vim is fast and highly configurable

Do you ever pay attention to the start-up time of VSC or Atom. Vim is faster.
Even with many themes, plugin, etc. Config is still one file.

#### Vim has a lot of fantastic plugins

Vim has a lot of plugin from text highlining and auto-completion
to Go/Flutter/Jenkinsfile support. And still, the package manager takes care of everything. You can change machine, download `.vimrc` run `:PluginInstall`
and get the same setup as at home/work/school. That is awesome. Try to do this
with VSC.

#### Regular IDEs require mause usage

I'm working on 12,5" ThinkPad x270, so taking care about
freeport(Yes I have only one USB port) and the mouse is a waste of energy.
I can work from everywhere and keybindings become very natural. Especially
when I switch to [qutebrowser][2]. My IT life started to be very comfortable
and time-effective.

#### Macros

In Vim is possible to record your macro with just two moves,
for example part of [Wiki][3]

Given some data like the following:

```python
one    first example
two    second example
three    third example
four    fourth example
```

Suppose you want to change the data to make a dictionary
for a Python program, with this result:

The following shows one way to record a suitable macro.

Put the cursor on the first line.
Type qd (the q starts recording; the d is the register where keys will be recorded).
Type the following command to change the first
the sequence of whitespace to "': '":

```bash
:s/\s\+/': ' (then press Enter)
 ```

Type the following to insert four spaces followed
by "'" at the start of the line:

```bash
I    ' (then press Escape)
```

Type the following to append "'," to the line:

```bash
A', (then press Escape)
```

Type the following to move the cursor to the start
of the line, then down to the next line:

```bash
0j (or press Enter)
```

Type q to stop recording the macro.
The cursor should now be on the second line.
Type @d to playback the macro once. That should
change the second line, with the cursor finishing
on the third line. Type 2@@ to finish

And buum magic:

```python
data = {
    'one': 'first example',
    'two': 'second example',
    'three': 'third example',
    'four': 'fourth example',
}
```

#### Flutter support

I planning to work with a mobile app and I decided that [Flutter][5]
could be a nice tool for my needs. Unfortunately, Android Studio is so big,
and slow, and resources consuming. Here comes Vim with plugins, shortcuts
, and minimal hardware requirements. It's just working, that my whole Flutter
config.

```vim
"" Flutter
Plug 'thosakwe/vim-flutter'
Plug 'dart-lang/dart-vim-plugin'
Plug 'natebosch/vim-lsc'
Plug 'natebosch/vim-lsc-dart'
let g:lsc_auto_map = v:true


"" Flutter keys
noremap <Leader>df :<C-u>:DartFmt<CR>
noremap <Leader>frun :<C-u>:FlutterRun<CR>
noremap <Leader>fr :<C-u>:FlutterHotReload<CR>
noremap <Leader>frs :<C-u>:FlutterHotRestart<CR>
noremap <Leader>fq :<C-u>:FlutterQuit<CR>
```

#### Vim support mdl, flake, linters

When I'm writing this post I have buildin mdl support, just after
tool installation. It works the same with python's flake8, golinters
etc. I don't like this feeling when VCS starts to download some stuff and I
have no idea what's happened. Here I have full control.

#### Keybindings and buffers

I don't like [NERDTree][4], I prefer standard buffers. They are
faster and give better control on `files under usage`. Short examples:

- When I want to go to the end of the line:

    ```bash
    A(Shift+a)
    ```

- When I copy line:

    ```bash
    V, y(Shift+v, next y)
    ```

- When I past line:

    ```bash
    p(just p)
    ```

- Beginning of file:

    ```bash
    gg(double g)
    ```

- End of file:

    ```bash
    G(Shift+g)
    ```

- Line 123 with error on it:

    ```bash
    :123<Enter>
    ```

- Change the word with confirmation:

    ```bash
    :%s/old_word/new_word/gc
    ```

That's sweet, isn't it?

## Summary

So that's why I'm learning Vim, I don't like [Emacs][6],
because is a bit heavier, and require downloading. The rest of
popular IDE like VSC or Atom are too slow, and configuration
is annoying. Sublime Text is nice but isn't free. So I decided
to switch. The learning curve is not very flat, but in my opinion, it
only requires some willingness. However when I need to write some
Java code I still prefer [IntelliJ][7], but for Go/Python/Clojure
stuff Vim probably becomes my tool of choice. Even working with
Markdown, YAML, HCL, and Flutter(Dart) is very handy and smooth.
So I recommend at least make some attempts to feel like Hollywood's
hacker, maybe you will stay a bit longer.

btw. I have some delays... I will deliver stuff related to
Terraform, Docker Python API, Ansible, and Flutter, but it requires some time.
Even this small post took almost 2h... but stay tuned.

[1]: https://www.vim.org/about.php
[2]: https://qutebrowser.org/
[3]: https://vim.fandom.com/wiki/Macros
[4]: https://github.com/preservim/nerdtree
[5]: https://flutter.dev/
[6]: https://www.gnu.org/software/emacs/
[7]: https://www.jetbrains.com/idea/
