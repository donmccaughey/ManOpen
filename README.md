# ManOpen

_ManOpen_ is a macOS GUI application for viewing Unix manual ("man") pages.
This repository is a fork of [ManOpen 2.6][11] by [Carl Lindberg][12].

[![Build Status][13]][14] [![Code Coverage][15]][16]

[11]: http://clindberg.org/projects/ManOpen.html
[12]: mailto:lindberg@clindberg.org
[13]: https://travis-ci.org/donmccaughey/ManOpen.svg?branch=master
[14]: https://travis-ci.org/donmccaughey/ManOpen
[15]: https://codecov.io/gh/donmccaughey/ManOpen/branch/master/graph/badge.svg
[16]: https://codecov.io/gh/donmccaughey/ManOpen

## Features

- Graphical interface for viewing Unix _man_ pages
- Open _man_ page by name or manual section + name
- Search all _man_ pages by keyword, using the `apropos` command
- Hyperlinks to related _man_ pages
- Quick section navigation
- Open _man_ files by path or `file:` URL
- Supports `x-man-page:` URLs to open a _man_ page or perform an `apropos` search
- `openman` command line tool to start _ManOpen_ from a terminal

## Requirements

_ManOpen_ is built on macOS High Sierra 10.13 using Xcode 9.3.  It should run on
OS X Yosemite 10.10 and later.

## License

For the files [`cat2html.l`][41] and [`cat2rtf.l`][42], "Permission is granted to
use this code."  All other files in the _ManOpen_ project are available under a
BSD-style license; see the [`LICENSE`][43] file for details.

[41]: ./cat2html/cat2html.l
[42]: ./cat2rtf/cat2rtf.l
[43]: ./LICENSE

## History

_ManOpen 1.0_ was originally released for NextSTEP by [Harald Schlangmann][51]
in 1993.  The first Mac OS X release, _ManOpen 2.0_, was released in October
1999 by Carl Lindberg.  _ManOpen 2.6_, from which this version is forked, was
released in March 2012.

[51]: mailto:schlangm@informatik.uni-muenchen.de

## Related

[_ManDrake_][61] is an [open source][62] macOS app by [Sveinbjörn Þórðarson][63]
for creating and editing man pages.

[61]: http://sveinbjorn.org/mandrake
[62]: https://github.com/sveinbjornt/ManDrake
[63]: http://sveinbjorn.org
