# The `manopen:` URL Scheme

In _ManOpen_ [version 2.6][1] and earlier, the `openman` command line tool uses
[_Distributed Objects_][2] to launch and communicate with `ManOpen.app`,
specifically the [`NSConnection`][3] and [`NSDistantObject`][4] classes.
Unfortunately, _Distributed Objects_ is now long deprecated, so a replacement
communication method is needed going forward.

[1]: http://clindberg.org/projects/ManOpen.html
[2]: https://web.archive.org/web/20090418184917/http://developer.apple.com/documentation/Cocoa/Conceptual/DistrObjects/DistrObjects.html
[3]: https://developer.apple.com/documentation/foundation/nsconnection
[4]: https://developer.apple.com/documentation/foundation/nsdistantobject

The `openman` tool operates in three modes, with the following required and
optional parameters being sent to `ManOpen.app`:

1. lookup _man_ page by `name`, with optional `section`, `MANPATH` and
   `background` flag
1. _apropos_ search by `keyword`, with optional `MANPATH` and `background` flag
1. open _man_ file by `path`, with optional `background` flag

The `MANPATH` parameter can be used to modify the _man_ page search path. The
`background` parameter can be used to display the requested _ManOpen_ document
without forcing its window into the foreground.

The [_Launch Services_][5] APIs in the _Core Services_ framework provides a
modern programmatic way to open `ManOpen.app` and display a document. _Launch
Services_ is built around URLs. 

[5]: https://developer.apple.com/documentation/coreservices/launch_services?language=objc

The `manopen:` scheme is designed for launching _ManOpen_ in the three modes of
the `openman` tool. It is similar to the [`x-man-page:`][6] scheme.

[6]: ./x-man-page_URL_Scheme.md

## _man_ Page Lookup

The _man_ page lookup URL has one of the formats:

    manopen://<section>/<name>?MANPATH=<man_path>&background=[true|false]
    manopen:///<name>?MANPATH=<man_path>&background=[true|false]

where `<section>` is the _optional_ manual section number and `<name>` is the
_man_ page name to look up. The query parameters `MANPATH` and `background` are
optional. Unlike the `x-man-page:` scheme, exactly two slashes are required
before the `<section>`, whether present or not, and exactly one slash is
required before the `<name>`.

## _apropos_ Keyword Search

The _apropos_ keyword search URL has the format:

    manopen://apropos/<keyword>?MANPATH=<man_path>&background=[true|false]

where `<keyword>` is the keyword to search for. The query parameters `MANPATH`
and `background` are optional. Exactly two slashes are required before
`apropos` and exactly one slash is required before the `<keyword>`.

## Open _man_ File by Path

The _man_ file URL has the format:

    manopen:<abs_file_path>?background=[true|false]

where `<abs_file_path>` is the absolute path of the _man_ page file to open.
The query parameter `background` is optional. The absolute file path must begin
with exactly one slash.

## Query Parameters

Use the `MANPATH` parameter to restrict or expand the _man_ page or _apropos_
search to a particular path. The value of `MANPATH` should be one or more
absolute paths; join multiple paths together with the colon (`:`) character.
The value of `MANPATH` should be URL encoded if it contains the ampersand (`&`)
character. If not specified, _ManOpen_ uses the search path given in its
preferences.

The `background` parameter must have the value `true` or `false`. If not
specified, _ManOpen_ will open a new window in the foreground.

## Examples

    manopen:///grep
    manopen://3/printf?background=true
    manopen://apropos/edit?MANPATH=/usr/man:/usr/local/man
    manopen:/usr/local/share/man/man1/wget.1
    
