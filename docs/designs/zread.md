# zread

*   **Author:** Pierry Borges
*   **Status:** Draft
*   **Date:** 2026-11-08

--------------------------------------------------------------------------------

## Overview

zread is a macOS app that opens a project folder from the terminal
(`zread .`) and shows its Markdown files as articles to read. The default
screen is the rendered text in a single column, with typography and components
inspired by reading on Medium. Editing exists but is secondary: one shortcut
switches the screen to the raw text, and another saves.

The relationship with Zed is inverted. Zed opens on code and can show a preview.
zread opens on reading and can show the Markdown source.

## The Problem

Repository Markdown (README, `docs/`, design docs) is read today inside code
editors. In those editors the preview is a secondary panel: the typography was
not designed for long text, and the tree, tabs, and other editor controls
surround the text.

Adjusting this inside the editor solves only part of it. VS Code accepts custom
CSS in the preview (`markdown.styles`), which improves the typography, but the
preview is still a panel inside an editor. zread is justified only by what a
theme cannot deliver: a window made only for reading, opened directly from the
terminal, in which the rendered text is the initial screen.

Cut criterion for the whole project: **a feature that does not improve reading
repository Markdown stays out.** Editing is included as a declared exception, to
fix what is noticed during reading.

## Goals

**Opening**

*   `zread .` opens the current folder, and `zread caminho/arquivo.md` opens
    directly on that file.
*   When opening a folder, the first file shown is the root `README.md`. Without
    a README, the screen shows the file tree.

**Reading**

*   Reading mode is always the initial mode, for every opened file.
*   The text sits in a central column of limited width, around 680 px.
*   Wide tables and code blocks do not break the text column: they scroll
    horizontally inside the block itself.
*   Rendered components: title, subtitle, paragraph, quote, list, image, link,
    table, code block with syntax highlighting, inline code, separator, and task
    list.
*   Minimal interface: a sidebar collapsible by a button in the title bar, with
    the file tree and the settings. No tabs or toolbar.

**Repository navigation**

*   The tree lists only the folders that contain Markdown.
*   `.git`, `node_modules`, and folders listed in `.gitignore` do not appear.
*   A relative link between Markdown files opens the target inside zread.
    Anchors (`#secao`) scroll to the heading. An external link opens in the
    default browser.
*   An image with a relative path is loaded from the repository.

**Editing (secondary)**

*   `Cmd+E` switches between reading and raw text. `Cmd+S` saves.
*   When switching, the screen keeps the passage being read, in both directions.
*   No unsaved change is lost without a warning, when switching files or closing
    the window.

**Theme**

*   Light mode: Cloud Dancer background (PANTONE 11-4201, `#F0EEE9`) with
    near-black text.
*   Dark mode: very dark background, close to black, with white text.
*   The theme follows the macOS appearance by default, and can be set to light or dark in the settings.
*   Body in Source Serif Pro, embedded in the app (SIL OFL license). Headings and
    interface in Helvetica Neue, from the system. Code always in Menlo.
*   Reading settings in the sidebar, applied immediately and kept between
    sessions: font (Serif or monospaced), size, letter spacing, line height, and
    primary color, used in headings, links, quotes, and separators.

**Lightness (proposed targets, not yet measured)**

*   From Enter on `zread .` to text on screen: up to 500 ms on Apple Silicon,
    with the app closed.
*   Installed app: up to 30 MB.
*   Memory with one document open: up to 200 MB, adding up all the app's
    processes.

## Non-Goals

*   Being a code editor, or opening files that are not Markdown.
*   WYSIWYG or block-based editing.
*   Notes vault: wikilinks, backlinks, graph, tags.
*   Search across the whole repository in the first version.
*   Tabs or multiple documents side by side.
*   Configurable themes beyond the reading settings listed in the Goals.
*   Plugins, sync, publishing, or export.
*   Windows and Linux.
*   Rendering Mermaid or math in the first version.
*   Reproducing the Medium brand: logo, name, and social features such as claps,
    comments, and profile. The reference is only the reading experience.

## Open Questions

None open. Decisions made during drafting:

*   **Heading font**: Helvetica Neue. Söhne, associated with Medium, is licensed
    and is not on this machine.
*   **Dark mode**: background `#0A0A0A`, text `#FFFFFF`, at the author's request.
    Pure white in long text can cause glare. The values live in CSS variables,
    and real reading tests can adjust them.
*   **Change on disk**: when the window gains focus, the app compares the
    modification date and reloads, keeping the passage. With an unsaved edit, it
    does not reload. `Cmd+S` asks for confirmation if the file changed on disk.
*   **Mermaid and math**: out of v1. The block appears as code.
*   **Very large file**: above 2 MB, it renders without syntax highlighting, and
    the opening targets no longer apply.

## Critical User Journeys (CUJs)

### CUJ 1: Read a project's docs

*   **Given**: a terminal in a repository folder with `README.md` and `docs/`.
*   **When**: the user runs `zread .` and clicks a relative link in the README.
*   **Then**: the README appears in reading mode, and the linked document opens
    in the same window, also in reading mode.

### CUJ 2: Fix an error while reading

*   **Given**: a document open in reading mode, scrolled to the middle.
*   **When**: the user presses `Cmd+E`, fixes the text, presses `Cmd+S` and
    `Cmd+E`.
*   **Then**: the file on disk contains the fix, and reading returns to the same
    passage with the corrected text.

### CUJ 3: Read at night

*   **Given**: macOS in dark appearance.
*   **When**: the user opens any document.
*   **Then**: the document appears with a very dark background and white text,
    with no manual adjustment.

## Technical Plan (Architecture)

zread is an AppKit app in Swift, without a sandbox, distributed outside the App
Store. It converts Markdown to HTML with cmark-gfm and shows the result in a
single `WKWebView`. Source mode is a plain text `NSTextView`, placed where the
WebView was.

```text
terminal: zread .
   |
   v
CLI (zread)  -- absolute path -->  open -b <bundle id> <path>
                                         |
                                         v
                              AppDelegate / WindowController
                              (one window per open root)
                                 |                    |
                     1. initial document     2. after the first text
                                 v                    v
                         MarkdownRenderer        RepoScanner
                          (cmark-gfm)        (git ls-files or scan)
                                 |                    |
                                 v                    v
                         ReaderView (WKWebView)   FileTree (sidebar)
                          |            ^
              link click  |            | zread:// (images, CSS, JS)
                          v            |
                     LinkRouter    LocalScheme (only inside the root)

Cmd+E:  ReaderView <--> SourceEditor (NSTextView), exchanging line number
Cmd+S:  SourceEditor --> writes to disk --> MarkdownRenderer --> ReaderView
```

### Measured baseline

A throwaway prototype (AppKit window, one `WKWebView`, 400 sections of synthetic
HTML, no parser) was run 5 times on 2026-11-08:

| Item | Result |
| --- | --- |
| Text loaded, runs 2 to 5 | 226 to 265 ms |
| Text loaded, first run | 1,624 ms |
| Combined memory (app + WebKit processes) | 175 to 176 MB |
| Binary | 109 KB |
| Ghostty, for comparison | 62 MB on disk, 153 MB running with open sessions |
| Zed, for comparison | 176 MB on disk, memory not measured |

The memory figure adds up RSS, which counts shared system pages more than once,
so the real value is lower. About 25 MB remain up to the 200 MB target before
adding the parser, CSS, and images. The 500 ms target applies to opening with
WebKit already in the disk cache. The first run after a boot can exceed it.

### Components

*   **`zread` CLI**: small binary inside the bundle. Resolves the argument to an
    absolute path and asks macOS to open the app with it, via `open -b`.
    Repeating the command with the app open reuses the running instance. The
    command reaches the `PATH` through a symlink in `/usr/local/bin`, created by
    an app menu item.
*   **WindowController**: one window per root folder. Reopening the same root
    brings the existing window to the front.
*   **MarkdownRenderer**: calls cmark-gfm with the table, task list,
    strikethrough, and autolink extensions, and with the source position option,
    which records each block's line in `data-sourcepos`. Delivers an HTML
    fragment.
*   **ReaderView**: reuses the same `WKWebView`, swapping only the content. The
    page shell, CSS, and JS come from the bundle.
*   **Theme**: a CSS file with color variables, switched by
    `prefers-color-scheme`. System fonts, none embedded.
*   **Syntax highlighting**: embedded highlight.js, with common languages, loaded
    only when the document has a code block.
*   **RepoScanner**: in a git repository, uses `git ls-files -co
    --exclude-standard` filtering `*.md` and `*.markdown`, which already respects
    `.gitignore`. Outside git, walks the folder ignoring `.git` and
    `node_modules`. Runs after the first text, so as not to delay opening.
*   **LocalScheme**: `WKURLSchemeHandler` for `zread://`. Serves images relative
    to the root and refuses any path that, once resolved, leaves it.
*   **LinkRouter**: decides each WebView navigation. A Markdown file inside the
    root opens in zread, `#ancora` scrolls within the page, and `http(s)` and
    `mailto` go to the system.
*   **SourceEditor**: plain text `NSTextView`, Menlo, no highlighting. Keeps the
    unsaved change state and asks for confirmation when switching files or
    closing.

### Switching while keeping the passage

*   **Reading to source**: a script finds the first visible block, reads the
    line in `data-sourcepos`, and the `NSTextView` scrolls to that line.
*   **Source to reading**: the app takes the first visible line, renders again
    if there was a change, and the script scrolls to the last block whose
    starting line is less than or equal to it.

Precision is per block. A long paragraph returns to its start, not to the exact
sentence.

### Security

Files from a cloned repository are untrusted content, and the app has no
sandbox. Therefore:

*   Raw HTML inside Markdown is discarded, which is cmark's default mode. The
    cost is real: READMEs with `<img>` of defined width, `<details>`, or HTML
    alignment lose those elements.
*   A Content-Security-Policy allows script, style, and image only from
    `zread://`. Remote images are blocked, which prevents opening a document from
    notifying an external server, and also means README badges do not appear.
*   `LocalScheme` restricts reading to the open root.

## Alternatives Considered

There was no prior brief. These alternatives came from discussion during
drafting. Only WKWebView was measured. The other numbers are estimates.

### Alternative A: CSS theme in an existing editor's preview

*   **Pros**: almost no code. VS Code accepts custom CSS through the
    `markdown.styles` setting.
*   **Cons**: the preview is still a panel inside an editor, and it does not open
    directly in reading from the terminal.
*   **Reason for Rejection**: Rejected by author: the chosen pain is the preview
    being secondary inside an editor, and a theme changes only the typography.

### Alternative B: Native with TextKit, no WebView

*   **Pros**: eliminates the WebKit processes, about 76 MB measured in the
    prototype. App estimated at 3 to 8 MB.
*   **Cons**: tables, code blocks with their own scrolling, and images require
    handmade embedded views, and each component becomes its own code.
*   **Reason for Rejection**: Rejected by author: WKWebView measured 175 MB, in
    the range of Ghostty's 153 MB in use, and delivers the components through
    CSS. The memory savings do not pay for the per-component work.

### Alternative C: GPUI, Zed's interface framework

*   **Pros**: same technique as Zed, direct drawing on the GPU, no WebView.
*   **Cons**: all reading components, text selection, and images would be written
    from scratch, on top of a dependency subject to API changes. Not measured.
*   **Reason for Rejection**: Rejected by author: Zed's renderer is made for
    editing code, and this product's reading does not need it.

### Alternative D: Tauri (Rust with the system WebView)

*   **Pros**: Rust ecosystem, app estimated at 10 to 15 MB.
*   **Cons**: uses the same WebView, so it does not reduce memory, and adds a
    Rust/JS bridge and startup cost.
*   **Reason for Rejection**: removed from the list of options during drafting,
    before the author's final choice: it has the cost of WKWebView plus one more
    layer, with no gain in lightness.

### Alternative E: Electron

*   **Pros**: complete web ecosystem and predictable Chromium.
*   **Cons**: embeds an entire browser in the app.
*   **Reason for Rejection**: never became an option: incompatible with the
    target of up to 30 MB approved by the author.

### Alternative F: Block-based editing

*   **Pros**: fixes a passage without leaving the reading position.
*   **Cons**: the parser needs to map blocks to file lines, and block boundaries
    are ambiguous in nested lists and tables.
*   **Reason for Rejection**: Rejected by author: editing is secondary, and the
    switched mode keeps reading separate and simple.

### Alternative G: WYSIWYG

*   **Pros**: the user never sees Markdown syntax.
*   **Cons**: requires a complete editing engine, and serializing back can
    reformat the file, producing noise diffs in the repository.
*   **Reason for Rejection**: Rejected by author: same reason as Alternative F,
    plus the weight against the lightness target.

### Alternative H: Notes vault or single-file scope

*   **Pros**: a vault would serve personal notes, and a single file would be the
    simplest possible app.
*   **Cons**: a vault requires an index and wikilinks and competes with Obsidian.
    A single file loses navigation between documents.
*   **Reason for Rejection**: Rejected by author: the chosen scenario is reading
    repository docs.

--------------------------------------------------------------------------------

## Detailed Implementation Plan

New project: the directory is empty and is not a git repository. All files are
created. Requirements: macOS 14 or later, Swift Package Manager, bundle id
`com.pierryborges.zread`, app without a sandbox. Only external code dependency:
`swift-cmark` (`gfm` branch, from `swiftlang/swift-cmark`).

### Target Files to Create/Modify

#### 1. `./Package.swift` (Create)

*   **Type / Scope**: Build.
*   **Proposed Changes**: Executable targets `ZreadApp` and `zread-cli`, library
    target `ZreadCore` for the testable logic, test target, and a dependency on
    `swift-cmark`. Separating `ZreadCore` allows testing without opening a
    window.

#### 2. `./Sources/ZreadCore/MarkdownRenderer.swift` (Create)

*   **Type / Scope**: Library.
*   **Proposed Changes**: `render(markdown: String) -> RenderedDocument`, with
    the HTML and the `hasCode` information. Uses cmark-gfm with table, task list,
    strikethrough, autolink, and source position. Without the unsafe option, to
    discard raw HTML. Rewrites `src` of relative images to `zread://`.

#### 3. `./Sources/ZreadCore/RepoScanner.swift` (Create)

*   **Type / Scope**: Library.
*   **Proposed Changes**: `scan(root: URL) async -> [FileNode]`. With `.git` in
    the root, runs `git ls-files -co --exclude-standard`. Without git or if the
    command fails, walks the folder ignoring `.git` and `node_modules`. Filters
    `.md` and `.markdown`, and returns a tree with only the folders that contain
    those files.

#### 4. `./Sources/ZreadCore/RootResolver.swift` (Create)

*   **Type / Scope**: Library.
*   **Proposed Changes**: From the argument, returns `root` and the initial file.
    Folder: it is the root, with `README.md` as the initial file, if it exists.
    File: walks up until it finds `.git`, or uses the file's folder as the root.

#### 5. `./Sources/ZreadCore/PathGuard.swift` (Create)

*   **Type / Scope**: Library, security.
*   **Proposed Changes**: `resolve(request:, root:) -> URL?`. Resolves symlinks
    and `..`, and returns nil if the result leaves the root. Used by
    `LocalScheme` and `LinkRouter`.

#### 6. `./Sources/ZreadCore/LinkClassifier.swift` (Create)

*   **Type / Scope**: Library.
*   **Proposed Changes**: Classifies a link as `internalMarkdown`, `anchor`,
    `external`, or `blocked`, without depending on AppKit. Only `http`, `https`,
    and `mailto` are external.

#### 7. `./Sources/ZreadCore/DocumentSession.swift` (Create)

*   **Type / Scope**: Library.
*   **Proposed Changes**: Keeps the path, text, loaded modification date, and
    unsaved change state. Exposes `load()`, `save()`, which signals a conflict if
    the disk changed, and `changedOnDisk()`. Saves by atomic write.

#### 8. `./Sources/ZreadApp/main.swift` and `./Sources/ZreadApp/AppDelegate.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: Startup and `application(_:open:)`, which receives the
    paths and forwards them to the window for that root. Menu with `Cmd+E`,
    `Cmd+S`, and the item to install the command. The disk check is triggered on
    focus.

#### 9. `./Sources/ZreadApp/WindowController.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: One window per root. Assembles the collapsible sidebar,
    the content area, and the switch between `ReaderView` and `SourceEditor`.
    Asks for confirmation when closing or switching files with an unsaved change.

#### 10. `./Sources/ZreadApp/ReaderView.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: Wraps the `WKWebView`. Loads the shell once and swaps
    the content by script. Exposes `topVisibleLine()` and `scrollTo(line:)`.

#### 11. `./Sources/ZreadApp/SourceEditor.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: Plain text `NSTextView` with Menlo, without automatic
    quote or dash substitutions. Exposes the same line operations as
    `ReaderView`.

#### 12. `./Sources/ZreadApp/FileTreeView.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: `NSOutlineView` fed by `RepoScanner`. Shows the tree as
    soon as the scan finishes, without blocking the first text.

#### 13. `./Sources/ZreadApp/LocalScheme.swift` and `./Sources/ZreadApp/LinkRouter.swift` (Create)

*   **Type / Scope**: App, security.
*   **Proposed Changes**: `LocalScheme` serves bundle resources and root images
    through `PathGuard`. `LinkRouter` applies `LinkClassifier` to each WebView
    navigation, and blocks the rest.

#### 14. `./Sources/ZreadApp/CLIInstaller.swift` (Create)

*   **Type / Scope**: App.
*   **Proposed Changes**: Creates the symlink `/usr/local/bin/zread` to the
    bundle's binary. Without permission, shows the command for the user to run.

#### 15. `./Sources/zread-cli/main.swift` (Create)

*   **Type / Scope**: CLI.
*   **Proposed Changes**: Resolves the argument (default `.`) to an absolute path
    and calls `open -b com.pierryborges.zread`. A nonexistent path produces an
    error on stderr and exit 1.

#### 16. `./Resources/page.html` (Create)

*   **Type / Scope**: Interface.
*   **Proposed Changes**: Page shell, with the Content-Security-Policy that only
    allows `zread://`.

#### 17. `./Resources/reader.css` (Create)

*   **Type / Scope**: Interface.
*   **Proposed Changes**: Color variables for light (`#F0EEE9`) and dark
    (`#0A0A0A` and `#FFFFFF`), column around 680 px, Charter in the body,
    Helvetica Neue in headings, Menlo in code. Styles for the components listed
    in the Goals, with their own horizontal scrolling in tables and code blocks.

#### 18. `./Resources/reader.js` (Create)

*   **Type / Scope**: Interface.
*   **Proposed Changes**: Swap content, read the first visible block through
    `data-sourcepos`, scroll to a line, generate anchors on headings, and load
    syntax highlighting only when `hasCode` is true.

#### 19. `./Resources/vendor/highlight.min.js` and `./Resources/vendor/highlight.css` (Create)

*   **Type / Scope**: Embedded dependency.
*   **Proposed Changes**: highlight.js build of common languages, with a pinned
    version and colors adjusted to both themes. No network access at runtime.

#### 20. `./Resources/Info.plist` (Create)

*   **Type / Scope**: Configuration.
*   **Proposed Changes**: Bundle id and document types for folder and Markdown,
    needed for macOS to deliver the paths to the app.

#### 21. `./scripts/bundle.sh` (Create)

*   **Type / Scope**: Build.
*   **Proposed Changes**: Compiles in release, assembles `zread.app` with the two
    binaries and `Resources`, and signs ad hoc.

#### 22. `./scripts/measure.sh` and `./Tests/fixtures/long.md` (Create)

*   **Type / Scope**: Measurement.
*   **Proposed Changes**: Runs the app with the test document and records time to
    text, combined process memory, and bundle size, to compare with the targets.

#### 23. `./Tests/ZreadCoreTests/*.swift` (Create)

*   **Type / Scope**: Unit tests.
*   **Proposed Changes**: One file per `ZreadCore` type: raw HTML discarded and
    `data-sourcepos` present; `.gitignore` respected and fallback without git;
    root resolved from folder and from file; path with `..` and symlink refused;
    classification of each link type; conflict on save.

#### 24. `./README.md` and `./.gitignore` (Create)

*   **Type / Scope**: Documentation and repository.
*   **Proposed Changes**: How to compile, install the command, and use it.
    Ignores `.build` and the generated app.

### Verification Plan

*   **Compilation/Build**: `swift build -c release` and `scripts/bundle.sh`.
*   **Unit Tests**: `swift test`.
*   **Static Analysis & Linting**: compilation without warnings.
*   **Test Coverage Requirement**: all the logic of `PathGuard`, `LinkClassifier`,
    and `DocumentSession.save`. The other `ZreadCore` types through the cases
    above.
*   **E2E/Integration**: run the three CUJs by hand in a real repository. Open a
    malicious document with `<script>`, a remote image, and a `../../` link and
    confirm that nothing executes, loads, or leaves the root.
*   **Performance**: `scripts/measure.sh`, 5 runs, with the targets of 500 ms,
    30 MB, and 200 MB. Record the first run separately.

--------------------------------------------------------------------------------

*Drafted with EGM*
