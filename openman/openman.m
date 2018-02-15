
#import <Foundation/Foundation.h>
#import <AppKit/NSWorkspace.h>
#import <libc.h>  // for getopt()
#import <ctype.h> // for isdigit()
#import "Application.h"
#import "LaunchServices.h"
#import "ManOpenURLComponents.h"
#import "SystemType.h"


static NSString *MakeNSStringFromPath(const char *filename)
{
    NSFileManager *manager = [NSFileManager defaultManager];
    return [manager stringWithFileSystemRepresentation:filename length:strlen(filename)];
}

static NSString *MakeAbsolutePath(const char *filename)
{
    NSString *currFile = MakeNSStringFromPath(filename);

    if (![currFile isAbsolutePath])
    {
        currFile = [[[NSFileManager defaultManager] currentDirectoryPath]
                     stringByAppendingPathComponent:currFile];
    }

    return currFile;
}

static void usage(const char *progname)
{
    fprintf(stderr,"%s: [-bk] [-M path] [-f file] [section] [name ...]\n", progname);
}

int main (int argc, char * const *argv)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString          *manPath = nil;
    NSString          *section = nil;
    NSMutableArray    *files = [NSMutableArray array];
    BOOL              aproposMode = NO;
    BOOL              forceToFront = YES;
    int               argIndex;
    NSUInteger        fileIndex;
    char              c;
    
    while ((c = getopt(argc,argv,"hbm:M:f:kaCcw")) != EOF)
    {
        switch(c)
        {
            case 'm':
            case 'M':
                manPath = MakeNSStringFromPath(optarg);
                break;
            case 'f':
                [files addObject:MakeAbsolutePath(optarg)];
                break;
            case 'b':
                forceToFront = NO;
                break;
            case 'k':
                aproposMode = YES;
                break;
            case 'a':
            case 'C':
            case 'c':
            case 'w':
                // MacOS X man(1) options; no-op here.
                break;
            case 'h':
            case '?':
            default:
                usage(argv[0]);
                [pool release];
                exit(0);
        }
    }

    if (optind >= argc && [files count] <= 0)
    {
        usage(argv[0]);
        [pool release];
        exit(0);
    }

    if (optind < argc && !aproposMode)
    {
        NSString *tmp = MakeNSStringFromPath(argv[optind]);

        if (isdigit(argv[optind][0])          ||
            /* These are configurable in /etc/man.conf; these are just the default strings.  Hm, they are invalid as of Panther. */
            [tmp isEqualToString:@"system"]   ||
            [tmp isEqualToString:@"commands"] ||
            [tmp isEqualToString:@"syscalls"] ||
            [tmp isEqualToString:@"libc"]     ||
            [tmp isEqualToString:@"special"]  ||
            [tmp isEqualToString:@"files"]    ||
            [tmp isEqualToString:@"games"]    ||
            [tmp isEqualToString:@"miscellaneous"] ||
            [tmp isEqualToString:@"misc"]     ||
            [tmp isEqualToString:@"admin"]    ||
            [tmp isEqualToString:@"n"]        || // Tcl pages on >= Panther
            [tmp isEqualToString:@"local"])
        {
            section = tmp;
            optind++;
        }
    }

    if (optind >= argc)
    {
        if ([section length] > 0)
        {
            /* MacOS X assumes it's a man page name */
            section = nil;
            optind--;
        }

        if (optind >= argc && [files count] <= 0)
        {
            [pool release];
            exit(0);
        }
    }
    
    id<LaunchServices> launchServices = [[LaunchServices new] autorelease];
    NSError *error = nil;
    Application *latestVersion = [Application latestVersionWithLaunchServices:launchServices
                                                           bundleIdentifier:@"cc.donm.ManOpen"
                                                                      error:&error];
    if (!latestVersion) {
        if (error) {
            fprintf(stderr, "%s:%li: %s",
                    error.domain.UTF8String, (long)error.code,
                    error.localizedDescription.UTF8String);
        } else {
            fprintf(stderr, "Unable to locate ManOpen application\n");
        }
        [pool release];
        exit(1);
    }
    
    NSMutableArray<NSURL *> *itemURLs = [[NSMutableArray new] autorelease];

    for (fileIndex=0; fileIndex<[files count]; fileIndex++)
    {
        ManOpenURLComponents *components = [[ManOpenURLComponents alloc] initWithFilePath:[files objectAtIndex:fileIndex]
                                                                             isBackground:!forceToFront];
        [components autorelease];
        [itemURLs addObject:components.url];
    }

    if (manPath == nil && getenv("MANPATH") != NULL)
        manPath = MakeNSStringFromPath(getenv("MANPATH"));

    for (argIndex = optind; argIndex < argc; argIndex++)
    {
        NSString *currFile = MakeNSStringFromPath(argv[argIndex]);
        if (aproposMode) {
            ManOpenURLComponents *components = [[ManOpenURLComponents alloc] initWithAproposKeyword:currFile
                                                                                            manPath:manPath
                                                                                       isBackground:!forceToFront];
            [components autorelease];
            [itemURLs addObject:components.url];
        } else {
            ManOpenURLComponents *components = [[ManOpenURLComponents alloc] initWithSection:section
                                                                                        name:currFile
                                                                                     manPath:manPath
                                                                                isBackground:!forceToFront];
            [components autorelease];
            [itemURLs addObject:components.url];
        }
    }
    
    BOOL success = [launchServices openItemURLs:itemURLs
                                  inApplication:latestVersion
                                          error:&error];
    if (!success) {
        if (error) {
            fprintf(stderr, "%s:%li: %s",
                    error.domain.UTF8String, (long)error.code,
                    error.localizedDescription.UTF8String);
        } else {
            fprintf(stderr, "Unable to launch ManOpen application\n");
        }
        [pool release];
        exit(1);
    }

    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
