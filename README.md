<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Artwork/IconWithText~dark.png">
  <img src="Artwork/IconWithText.png" alt="DoriKit logo" height="70">
</picture>

# Greatdori!

Greatdori includes iOS, macOS and watchOS app,
built with [DoriKit](https://github.com/Greatdori/DoriKit)

| **Target** | **Status** |
|---:|:---:|
| Greatdori           | ![Greatdori Build Status](https://img.shields.io/github/actions/workflow/status/Greatdori/Greatdori/build-greatdori.yml)|
| Greatdori Watch App | ![Greatdori Watch App Build Status](https://img.shields.io/github/actions/workflow/status/WindowsMEMZ/Greatdori/build-greatdori-watch.yml)|

## Building
Xcode 26.0 and Swift 6.2+ is required for building this project.

CMake is required for building from Xcode Project,
you can install it by Homebrew if you don't have one:

```sh
brew install cmake
```

First, create a directory for the Greatdori! project:

```sh
mkdir Greatdori
cd Greatdori
```

Then clone this project by Git:

```sh
git clone https://github.com/Greatdori/Greatdori.git
cd Greatdori
```

Note that there should be two `Greatdori` folders,
your current path like this:

```sh
$ pwd
/path/to/Greatdori/Greatdori
```

Use the `utils/update-checkout` script to checkout all repositories
that Greatdori! needs. Add `--clone` option for the first time
to clone all repositories:

```sh
utils/update-checkout --clone
```

After cloning all repositories needed, use `utils/generate-workspace`
to generate a `xcworkspace` for building project:

```sh
utils/generate-workspace
```

Open `Greatdori.xcworkspace`, then select a scheme you want to build.

### Schemes
There're several schemes in Greatdori! project:

- **Greatdori**: The Greatdori! app for iOS, iPadOS and macOS;
- **Greatdori Widgets**: Widget extension for **Greatdori** scheme;
- **Greatdori Watch App**: The Greatdori! app for watchOS;
- **Greatdori Watch Widgets**: Widget extension for **Greatdori Watch App** scheme;
- **BuiltinCardCollections**: Built-in card collection for widgets;
- **DoriKit**: The DoriKit framework;
- **DoriAssetShims** Objective-C shims for offline asset features in DoriKit;
- **DoriKitMacros**: Implementations of macros in DoriKit;
- **DoriKitTests**: Tests for DoriKit;
- **DoriEmoji**: Emoji collections for community UI of DoriKit;
- **DoriResource**: Commonly used binary resources for DoriKit;
- **Greatdori Installer**: Generates a `pkg` installer for macOS app;
- **CardCollectionGen**: A CLI tool which generates built-in card collections;
- **GreatLyrics**: A tool for making lyrics file of songs.
- **libgit2**: LibGit2 and its dependencies, required for *DoriAssetShims*.

Besides, some targets have a corresponding *Without Pre-Cache* scheme,
which builds the target without [pre-cache](#pre-cache) for DoriKit.

### Pre-Cache
To make it faster to get some data which is updated less frequent,
DoriKit generates a `PreCache.cache` file in **compile-time**
and embeds it to `DoriKit.framework` bundle. This allows you to get some information
like character list from `DoriCache.preCache` without performing a network request.

Pre-Cache generation happens when you first build DoriKit for a configuration,
after you cleaned build folder, or if the previous generation date was over a week ago.
If you're experiencing a poor network connection
that makes you can't generate pre-cache successfully,
you can opt-out it by building your target from `Without Pre-Cache` scheme.

### Code Signing
All development teams of each targets are set to `Yuxuan Chen (8CZ4JT4F3M)`
which makes it easier for our CI runs and distribution workflows.
You have to change it to your own team before building,
or choose *None* if you build it only for simulator or macOS.
(And don't forget to change it back if you'd like to open a pull request!)

## Contributing to Greatdori!
Contributions to Greatdori! are welcomed and encouraged!
Fork the project, make changes and open your pull requests!

If you're experiencing some bugs, or have any suggestion to Greatdori!,
filing an issue for it is also welcomed.

### `Greatdori.xcodeproj` & `Package.swift`
`Greatdori.xcodeproj` is the main project file of Greatdori!,
we suggest you to open this project file in Xcode to make changes to Greatdori!.

`Package.swift` makes it easier to embed DoriKit in other projects,
and should not be used for editing code of Greatdori!,
because `xcodeproj` file maintains structures of all files in this project.

### Targets Relationship
```mermaid
---
config:
  layout: elk
---
flowchart TD;
    GA["Greatdori"] --> DK["DoriKit"] & GW["Greatdori Widgets"] & BCC["BuiltinCardCollections"]
    GWA["Greatdori Watch App"] <--> GA
    GW --> DK & BCC
    GWA --> DK & BCC & GWW["Greatdori Watch Widgets"]
    GWW --> DK & BCC
    BCC --> DK
    DKT["DoriKitTests"] --> DK
    DK --> DE["DoriEmoji"]
    DK --> DR["DoriResource"]
    DK --> DKM["DoriKitMacros"]
    DK -.-> PCG["PreCacheGen"]
    DK -.-> DAS["DoriAssetShims"]
    GI["Greatdori Installer"] --> GA
    CCG["CardCollectionGen"] --> DK
    GL["GreatLyrics"] --> DK
```

### About GYB Source Files
You may note that some source files have suffix `.swift.gyb` instead of `.swift`,
this kind of files are GYB templetes. GYB is a useful tool from the swiftlang project
which enables you to generate repeated source code from less code.

<details><summary>Usage of GYB</summary>

```

usage: gyb [-h] [-D NAME=VALUE] [-o TARGET] [--test] [--verbose-test] [--dump]
           [--line-directive LINE_DIRECTIVE]
           [file]

Generate Your Boilerplate!

positional arguments:
  file                  Path to GYB template file (defaults to stdin)

options:
  -h, --help            show this help message and exit
  -D NAME=VALUE         Bindings to be set in the template's execution context
  -o TARGET             Output file (defaults to stdout)
  --test                Run a self-test
  --verbose-test        Run a verbose self-test
  --dump                Dump the parsed template to stdout
  --line-directive LINE_DIRECTIVE
                        Line directive format string, which will be provided 2
                        substitutions, `%(line)d` and `%(file)s`. Example:
                        `#sourceLocation(file: "%(file)s", line: %(line)d)`
                        The default works automatically with the `line-
                        directive` tool, which see for more information.

    A GYB template consists of the following elements:

      - Literal text which is inserted directly into the output

      - %% or $$ in literal text, which insert literal '%' and '$'
        symbols respectively.

      - Substitutions of the form ${<python-expression>}.  The Python
        expression is converted to a string and the result is inserted
        into the output.

      - Python code delimited by %{...}%.  Typically used to inject
        definitions (functions, classes, variable bindings) into the
        evaluation context of the template.  Common indentation is
        stripped, so you can add as much indentation to the beginning
        of this code as you like

      - Lines beginning with optional whitespace followed by a single
        '%' and Python code.  %-lines allow you to nest other
        constructs inside them.  To close a level of nesting, use the
        "%end" construct.

      - Lines beginning with optional whitespace and followed by a
        single '%' and the token "end", which close open constructs in
        %-lines.

    Example template:

          - Hello -
        %{
             x = 42
             def succ(a):
                 return a+1
        }%

        I can assure you that ${x} < ${succ(x)}

        % if int(y) > 7:
        %    for i in range(3):
        y is greater than seven!
        %    end
        % else:
        y is less than or equal to seven
        % end

          - The End. -

    When run with "gyb -Dy=9", the output is

          - Hello -

        I can assure you that 42 < 43

        y is greater than seven!
        y is greater than seven!
        y is greater than seven!

          - The End. -

```

</details>

### Testing
You have to run testing by `DoriKitTests` scheme in Greatdori.xcodeproj (instead of Package.swift).

## License
This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE.txt) file for details.
