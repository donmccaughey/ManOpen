# The `x-man-page:` URL Scheme

The `x-man-page:` scheme has been supported by `Terminal.app` since at least Mac
OS X 10.3 Panther, though there doesn't appear to be any official documentation for the
scheme. There are two versions of `x-man-page:` URLs: _man_ page lookup and
_apropos_ keyword search. _ManOpen_ supports the `x-man-page:` scheme. The
[`ManOpenURLHandlerCommand`][1] class implements the  `x-man-page:` support.

[1]: ./../ManOpen/ManOpenURLHandlerCommand.m

## _man_ Page Lookup

The _man_ page lookup URL has the format:

    x-man-page://<section>/<name>
    
where `<section>` is the _optional_ manual section number and `<name>` is the _man_
page name to look up. Examples of _man_ page lookup, using the `open` command in a
terminal window:

    open "x-man-page://1/printf"
    open "x-man-page:///grep"

The `Terminal.app` is fairly tolerant of the number of slashes before the `<name>` portion
of the URL, but requires exactly two slashes before the `<section>`. All these variations
are accepted:

    # with section and name
    open "x-man-page://1/printf"
    open "x-man-page://1//printf"
    open "x-man-page://1///printf"
    
    # with name only
    open "x-man-page:/grep"
    open "x-man-page://grep"
    open "x-man-page:///grep"
    open "x-man-page:////grep"

## _apropos_ Keyword Search

The _apropos_ keyword search URL has the format:

    x-man-page:///<keyword>;type=a

where `<keyword>` is the keyword to search for. Examples of _apropos_ keyword search,
using the `open` command in a terminal window:

    open "x-man-page:///print;type=a"
    open "x-man-page:///regex;type=a"

The `Terminal.app` is fairly strict about the number of slashes before the `<keyword>`
part of the URL. All of these variations are accepted:

    open "x-man-page:///regex;type=a"
    open "x-man-page:/regex;type=a"

A `<section>` can be given for _apropos_ search URLs, but is ignored.

    # section "1" is ignored
    open "x-man-page://1/print;type=a"

## `x-man-page:` Scheme References

Sources of information on the `x-man-page` scheme:

- [_x-man-page: URL handler studied for the OSX Terminal.app_][2].
- [_On Viewing `man` Pages_][3]
- [_Shell Tricks: man pages_][4]
- [_10.3: Use the x-man-page URL type to open UNIX man pages_][5]

[2]: https://github.com/ouspg/urlhandlers/blob/master/cases/x-man-page.md
[3]: http://scriptingosx.com/2017/04/on-viewing-man-pages/
[4]: http://brettterpstra.com/2014/08/05/shell-tricks-man-pages/
[5]: http://hints.macworld.com/article.php?story=20031225072602242
