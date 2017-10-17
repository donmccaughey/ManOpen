
ManOpen v2.6 by Carl Lindberg  February 2012

	Please send any comments, suggestions or bug reports to
	lindberg@clindberg.org.

	This program is provided ``AS IS'' and without any warranty.


	ManOpen is a graphical interface for viewing Unix manual pages,
which are the standard documentation for Unix command line programs,
programmer libraries, and other system information.  It can open files
directly or be given titles, in which case it will display the output
from the "man" command-line program.  An apropos interface is also
provided, which is basically a quick-and-dirty search of the man page
databases.  Services are provided to other applications to open selected
files/titles or do apropos searches using the selected text.

	Version 2.6 changes:

    - Requires MacOS X 10.4; works on 10.7
    - Updated to use more current MacOS interface
    - Added a "Copy URL" function to copy the current page URL
      to the clipboard (suggested by Quinn)
    - Handle versions of groff/grotty which use ANSI escape sequences
      (reported by Kim Holburn)
    - Preference on Lion to disable saving of open windows upon quit

	ManOpen can be useful for opening a man page without dropping
down to the command line, browsing and searching through long and
complex man pages, or simply for printing them out.

	Also included is an "openman" command line tool, which is similar
to "man" except it will display the man pages in ManOpen.app instead
of directly to the terminal.

	ManOpen should run on MacOS X 10.4 and higher.  Source code is 
available.  To install the app, put ManOpen.app in one of the standard
Application directories, such as /Network/Applications, /Applications
or ~/Applications.  You may have to log out and back to have the
services work.

    To install the "openman" tool, put it in one of the directories in
the Unix $PATH, such as /usr/local/bin.  Put its "openman.1" man page
in a standard man page directory, such as /usr/local/man/man1.
[Note that /usr/local/bin may not be part of the default PATH.
Adding "set path = (/usr/local/bin $path)" to your
~/.cshrc file is one way to set it back, for tcsh users.]


	For those who remember, there was a ManOpen 1.0 application
by Harald Schlangmann that ran on NEXTSTEP computers.  This is a much
updated version that adds many features.  Thanks are due to
Mr. Schlangmann for the inspiration, and his internal cat2rtf tool
which is also used in this version.

	Hope you find this useful,
	
	-Carl Lindberg
	lindberg@clindberg.org
	lindberg@mac.com


 * Copyright (c) 2000-2012 Carl Lindberg

 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
