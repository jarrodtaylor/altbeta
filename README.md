# Alternator

> **al·ter·na·tor:**
> A device that converts mechanical energy to electrical energy.

A CLI tool for building static websites on your Mac.
Layouts, includes, and variables in HTML, CSS, and JS.
Markdown built-in. Localhost server included.

## Getting Started

Run `alternator --help` for a quick reference:

```shell
~/website % alternator --help
OVERVIEW: Alternator builds static websites.

Visit https://jarrodtaylor.github.io/alternator to learn more.

USAGE: alternator [<source>] [<target>] [--port <port>]

ARGUMENTS:
  <source>             Path to your source directory. (default: .)
  <target>             Path to your target directory. (default: <source>/_build)

OPTIONS:
  -p, --port <port>    Port for the localhost server.
  --version            Show the version.
  -h, --help           Show help information.
```

Alternator uses the files from `<source>` to build your website into `<target>`:

```shell
~/website % alternator path/to/source path/to/target
```

`<source>` can be structured any way you like.

If you give Alternator a `--port` it will make `<target>` available on localhost:

```shell
~/website %  alternator path/to/source path/to/target --port 8080
[watch] watching path/to/source for changes
[serve] serving path/to/target on http://localhost:8080
^c to stop
```

Changes in `<source>` are automatically rebuilt while the server is running.

