    /*
        cat2rtf.l: cat to RTF converter specification
        (c) 1993 by Harald Schlangmann
        Permission is granted to use this code. Send additions
        and bug reports to my address below.
        
        v1.0    Harald Schlangmann, July 20 1993
                schlangm@informatik.uni-muenchen.de
        v1.1    Bold style x^H{x^H}* implemented.
        
        v2.0    Carl Lindberg lindberg@mac.com
                Added blank line suppressing.
        v2.1    Added links.
        v2.2    Added RTF hyperlinks
     */

    #include <string.h>
    
    #if defined(__APPLE__) && !defined(NeXT)
    #define RTF_HYPERLINKS
    #endif

    #define BOLDFLAG    1
    #define ULINEFLAG    2

    int flags = 0, neededflags = 0;
    
    #define SETB    neededflags |= BOLDFLAG
    #define UNSETB  neededflags &= ~BOLDFLAG
    #define SETU    neededflags |= ULINEFLAG
    #define UNSETU  neededflags &= ~ULINEFLAG
    
    /*
     *    Default settings, may be changed using options...
     */
    
    static char *startBold = "\n\\b ";
    static char *stopBold = "\n\\b0 ";
    static char *startULine = "\n\\ul ";
    static char *stopULine = "\n\\ulnone ";
    static char *startHeader = "\n\\f1 ";
    static char *stopHeader = "\n\\f0 ";
    static int addLinks = 0;
    static int markHeaders = 0; /* Mark headers with Helvetica */
    /*
     * 'lineCount' is here to squeeze multiple-blank lines (like 'more -s'
     * does with the traditional nroff output).  By default, a max of 3
     * consecutive blank lines are allowed. A value of -1 means to not
     * squeeze lines at all.  -CEL
     */
    static int lineCount = 0;
    static int maxLineCount = 3;

    /* Decode a UTF8 sequence to return the unicode number */
    static unsigned decodeUTF8(unsigned char *buf, yy_size_t len)
    {
        int n = buf[0] & (0x7f >> len);
        yy_size_t i;

        for (i=1; i<len; i++)
            n = (n << 6) | (buf[i] & 0x3f);

        return (unsigned)n;
    }

    static void emitPreamble(void) {
    
        fputs("{\\rtf0\\ansi{\\fonttbl\\f0\\fmodern Courier;\\f1"
        "\\fswiss Helvetica;}\n" "\\paperw14640\n" "\\paperh9600\n"
        "\\margl120\n" "\\margr120\n"
        "{\\colortbl;\\red0\\green0\\blue0;}\n"
        "\\pard\\tx1140\\tx2300\\tx3440\\tx4600"
        "\\tx5760\\tx6900\\tx8060\\tx9200"
        "\\tx10360\\tx11520\\f0\\b0\\i0\\ulnone"
        "\\fs24\\fc1\\cf1 ",stdout);
    }
    
    static void emitPostamble(void) {
    
        fputs("\n}\n",stdout);
    }

    #define adjust() if( neededflags!=flags ) _adjust()
    
    static void _adjust(void) {
    
        if( (flags^neededflags)&ULINEFLAG )
            fputs(neededflags&ULINEFLAG?
                startULine:stopULine,stdout);
        if( (flags^neededflags)&BOLDFLAG )
            fputs(neededflags&BOLDFLAG?
                startBold:stopBold,stdout);
        flags = neededflags;
    }
    

    /*
     *    emitChar escapes RTF-special characters...
     */
    static void emitChar(int ch) {        
        adjust();

        if (ch=='\n') {
            if (maxLineCount > 0 && lineCount > maxLineCount)
            {
                // Squeeze the blank line -- don't output it.
                return;
            }
            lineCount++;
        }
        else lineCount = 0;

        if( ch=='\n'||ch=='{'||ch=='}'||ch=='\\' )
            fputc('\\',stdout);
        fputc(ch,stdout);
    }

    static void emitChars(char *string, yy_size_t len)
    {
        yy_size_t i;

        for (i=0; i<len; i++)
            emitChar(string[i]);
    }

    /*
     *    ...emitString doesn't!
     */
    static void emitString(char *string) {
        adjust();
        lineCount = 0;
        fputs(string,stdout);
    }

    static void emitBackspacedLetters(char *charblock, yy_size_t lengthLeft, int doBold)
    {
        /* If there's a trailing backspace, then both letters are deleted, so print nothing */
        if (lengthLeft >= 4 && charblock[3] == '\010')
            return;

        /* If the characters are equal, they are printed on top of each other, so make it bold */
        if( charblock[0] == charblock[2] ) {
            if (doBold) SETB;
            emitChar(charblock[0]);
            if (doBold) UNSETB;
        }
        /* Otherwise, just emit the second character. */
        else {
    #ifdef DEBUGBACKSPACE
            fprintf(stderr, "Unknown backspace pair %c and %c\n", charblock[0], charblock[2]);
    #endif
            emitChar(charblock[2]);
        }
    }

    static void emitBackspacedText(char *text, yy_size_t length)
    {
        yy_size_t i=0;
        while (i < length) {
            if ((i < (length-1)) && text[i+1] == '\010') {
                emitBackspacedLetters(&text[i], 3, 0);
                i+=3;
            }
            else {
                emitChar(text[i]);
                i++;
            }
        }
    }

    /*
     * RTF has a "u" directive, which is followed by the unicode number
     * (as a signed 16-bit value).  For compatibility with readers that
     * do not support this, a "uc" directive is supported, where the
     * argument specifies the number of characters after the "u" to
     * ignore.  The idea is to put it alternate text, so that readers
     * which do not know "uc" or "u" will show the other (ASCII) text
     * instead.  We just show a '?'.  Put both inside a {...} section
     * so that the scope of the "uc" setting is limited.
     */
    static void emitUnicode(unsigned charNum)
    {
        short rtfVal = charNum;
        char rtfBuf[20];
        sprintf(rtfBuf, "{\\uc1\\u%hd?}", rtfVal);
        emitString(rtfBuf);
    }

ALLBUTUL     [^\n_\010]
NEEDQUOTE    [\\{}]
VERBATIM     [^\n_\010\x1B( \t\\{}\xC2-\xF4]
UPPER        [A-Z]
UPPERCONT    [-/A-Z0-9 \t()]
UPPERBS      {UPPER}\010{UPPER}
UPPERBSCONT  ({UPPERBS}|[ \t()])
UTF8START    [\xC2-\xF4]
UTF8CONT     [\x80-\xBF]
UTF8SEQ      {UTF8START}({UTF8CONT}{1,3})
SGRSTART     \x1B\[

%option 8bit
%option debug
%option noyywrap
%option noinput
%option prefix="cat2rtf"

%x FIRSTLINE

%%

    /*
     *    Start state FIRSTLINE is used to treat the first non-empty
     *    line special. (First line contains header).
     */

    /* Some X.org X11 pages have a weird #pragma at the start; strip it out. */
<FIRSTLINE>"#pragma".*\n {}

<FIRSTLINE>.        SETB; emitChar(yytext[0]);

<FIRSTLINE>.\n        {
                SETB;
                emitChar(yytext[0]);
                emitChar('\n');
                BEGIN(INITIAL);
                UNSETB;
            }

<FIRSTLINE>\n        UNSETB; emitChar('\n');

    /* Part of the X11 thing gets put on a separate line by nroff, sigh. */
^"vate/var/tmp/X11".*\n  {}

    /*
     *    Put a NeXTHelpLink next to likely looking links to other man pages if desired
     */
[_a-zA-Z][-a-zA-Z0-9._]*(-[ \t\n]+[-a-zA-Z0-9._]+)?[ \t\n]*"("[1-9n][a-zA-Z]?")"  {

            if (addLinks)
            {
                char namebuf[yyleng+1];
                int i;

                strcpy(namebuf, yytext);
                for (i=0; i<yyleng; i++)
                    if (namebuf[i] == '\n') namebuf[i] = ' ';

#ifdef RTF_HYPERLINKS
                emitString("{\\field{\\*\\fldinst{HYPERLINK \"manpage:");
                emitString(namebuf);
                emitString("\"}}{\\fldrslt ");
                emitChars(yytext, yyleng);
                emitString("}}");
#else
{
                static int linkNum = 763;  //seems to start around here
                char numbuf[10];

	            emitChars(yytext, yyleng);

                sprintf(numbuf, "%d", linkNum+=3);  //for some reason, Edit.app increments by 3
                emitString("{{\\NeXTHelpLink");
                emitString(numbuf);
                emitString(" \\markername ");
                emitString(";\\linkFilename manpage:");  // linkFilename is the parameter to set
                emitString(namebuf);
                emitString(";\\linkMarkername ");
                emitString(";}\n\\254}");
}
#endif
            }
        }

    /*
     *    Non-empty, all-uppercase lines are treated as headers
     */
^{UPPER}{UPPERCONT}*$    {
                SETB;
                if (markHeaders) emitString(startHeader);
                emitString(yytext);
                emitString("\\\n");
                if (markHeaders) emitString(stopHeader);
                UNSETB;
            }

    /* Similar for all-uppercase lines that use backspace for bolding */
^{UPPERBS}{UPPERBSCONT}*$ {
                SETB;
                if (markHeaders) emitString(startHeader);
                emitBackspacedText(yytext, yyleng);
                emitString("\\\n");
                if (markHeaders) emitString(stopHeader);
                UNSETB;
                emitChar('\n');
            }

    /*
     *    nroff +-
     */

"+"\010_        emitChar('\321');

    /*
     *    underline (part 1)
     */

{ALLBUTUL}\010_        {
                SETU;
                emitChar(yytext[0]);
                UNSETU;
            }

    /*
     *    nroff bullets
     */
o\010"+"        emitChar('\267');
"+"\010o        emitChar('\267');
o\010o\010"+"\010"+"        emitChar('\267');
"+"\010"+\010"o\010o        emitChar('\267');

    /*
     *    underline (part 2)
     */

_\010{ALLBUTUL}        {
                SETU;
                emitChar(yytext[2]);
                UNSETU;
            }

    /*
     *    handle further BS combinations
     */

.\010.\010?            {
                emitBackspacedLetters(yytext, yyleng, 1);
            }

  /* Same idea but with UTF-8 characters */
{UTF8SEQ}\010{UTF8SEQ}\010? {
        if (yytext[yyleng-1] != '\010') {
            char *backspace = index(yytext, '\010');
            if (backspace != NULL) {
                emitUnicode(decodeUTF8((unsigned char *)backspace+1, (yyleng - (backspace-yytext) - 1)));
            }
        }
    }

  /* If we find a UTF8 sequence, decode it */
{UTF8SEQ} {
    emitUnicode(decodeUTF8((unsigned char *)yytext, yyleng));
}

  /* Some versions of nroff/grotty use SGR (ANSI) escape sequences instead of the backspace hacks */
{SGRSTART}0?m          UNSETU;UNSETB;
{SGRSTART}1m           SETB;
{SGRSTART}[347]m       SETU;
{SGRSTART}(21|22)m     UNSETB;
{SGRSTART}(23|24|27)m  UNSETU;
{SGRSTART}[0-9;]+m     {/*ignore any other codes*/}

    /*
        group characters in VERBATIM to make this
        filter faster...
     */

[ \t]+                  emitString(yytext);
{VERBATIM}+/[^\010]  emitString(yytext);

    /*
        remaining specials
     */

\n            emitChar('\n');
.            emitChar(yytext[0]);

%%

static void usage() {

    fprintf(stderr,"Usage: cat2rtf [-gil] [-s <num>| -S] [<filename>]\n"
        "\tTranslate output of (g)nroff to RTF. If no\n"
        "\t<filename> is given, cat2rtf reads stdin.\n"
        "\tOption -g uses gray for bold characters,\n"
        "\toption -i uses italic characters for underlining.\n"
        "\toption -l will add NeXT help link buttons.\n"
        "\toption -s will allow only <num> consecutive blank lines,\n"
        "\toption -S will not do any squeezing of blank lines.\n"
        "\tRTF output is sent to stdout.\n");
    exit(1); 
}

int main(int argc, char *argv[])
{
    int c;

    yy_flex_debug = 0;

    while ((c = getopt(argc, argv, "dgGiISs:lH")) != EOF)
    {
        switch( c ) {
            case 'd':
                yy_flex_debug = 1;
                break;
            case 'g':
            case 'G':
                startBold = "\n\\gray333 ";
                stopBold = "\n\\gray0 ";
                break;
            case 'i':
            case 'I':
                startULine = "\n\\i ";
                stopULine = "\n\\i0 ";
                break;
            case 's':
                maxLineCount = atoi(optarg);
                break;
            case 'S':
                maxLineCount = -1;
                break;
            case 'l':
                addLinks = 1;
                break;
            case 'H':
                markHeaders = 1;
                break;
            case '?':
            default:
                usage();
        }
    }

    if( optind < argc )
        yyin = fopen(argv[optind], "r");
    else
        yyin = stdin;
    
    emitPreamble();
    BEGIN(FIRSTLINE);
    yylex();
    emitPostamble();
    
    /* Shuts up a compiler warning */
    if (0) unput('h');

    return 0;
}
