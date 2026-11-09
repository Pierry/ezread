![zread icon](docs/assets/icon.png)

# zread

Read the Markdown in your repo like it's an article.

[![Version](https://img.shields.io/github/v/tag/Pierry/zread?label=version&color=2f6fd0)](https://github.com/Pierry/zread/releases)
![macOS 14 or later](https://img.shields.io/badge/macOS-14%2B-18191b)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-2f6fd0)
[![Homebrew tap](https://img.shields.io/badge/Homebrew-tap-18191b)](https://github.com/Pierry/homebrew-zread)
[![MIT license](https://img.shields.io/github/license/Pierry/zread?color=2f6fd0)](LICENSE)

[Website](https://pierry.github.io/zread/)

![zread showing a document in a centered column, with the file list on the left](docs/assets/light.png)

## What it is

zread is a small Mac app for reading Markdown. Type `zread .` in any folder and
its docs open as clean, comfortable pages. The whole app is about 1 MB.

## The problem

Most of us read READMEs and design docs inside a code editor. The preview there
is a side panel, the type wasn't chosen for long text, and tabs and toolbars sit
all around it. Reading a good doc shouldn't feel like debugging.

zread opens on the text itself. Nothing else competes for your attention.

## Install

```sh
brew install pierry/zread/zread
```

That's it. You need macOS 14 or later and Xcode, because Homebrew builds the app
on your Mac. zread isn't notarized by Apple yet, and building it locally means
macOS opens it without a warning.

## Use it

```sh
zread .
zread docs/design.md
```

zread picks up where you left off: same file, same spot, same window. Links
between your docs open right in the app, and the sidebar lists every Markdown
file in the project. If a file changes on disk, zread reloads it when you come
back to the window.

Spotted a typo? Click Edit at the top right, fix it, click Save, then click Read
to go back to the page.

## Make it yours

Open Settings at the bottom of the sidebar to choose the theme, font, size,
letter spacing, line height and the color of your headings and links. Changes
show up as you make them, and zread remembers them.

![The settings in the zread sidebar](docs/assets/settings.png)

| Shortcut | What it does |
| --- | --- |
| `Cmd+E` | Switch between reading and editing |
| `Cmd+S` | Save |
| `Cmd+1` | Show or hide the sidebar |
| `Cmd+,` | Open settings |
| `Cmd+O` | Open a folder or file |

## Safe to point at any repo

zread never runs anything from a Markdown file. It drops raw HTML, skips remote
images, and only reads images inside the folder you opened. The tradeoff is that
remote badges in a README won't show up, including the ones on this page.

## Build it yourself

```sh
swift test
scripts/bundle.sh
open build/zread.app
```

Curious about the decisions behind it? The design doc is in
[docs/designs/zread.md](docs/designs/zread.md).

## License

MIT. zread also ships [cmark-gfm](https://github.com/swiftlang/swift-cmark),
[highlight.js](https://highlightjs.org/) and
[Source Serif Pro](https://github.com/adobe-fonts/source-serif). Their licenses
are in `Resources/vendor/`.
