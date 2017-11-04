#import <Foundation/Foundation.h>


/* Implement our x-man-page: scheme handler
 *
 * Terminal seems to accept URLs of the form x-man-page://ls , which means
 * the man page name is essentially the "host" portion, and is passed
 * as an argument to the man(1) command.  The double slash is necessary.
 * Terminal accepts a path portion as well, and will take the first path
 * component and add it to the command as a second argument.  Any other
 * path components are ignored.  Thus, x-man-page://3/printf opens up
 * printf(3), and x-man-page://printf/ls opens both printf(1) and ls(1).
 *
 * We make sure to accept all these forms, and maybe some others.  We'll
 * use all path components, and not require the "//" portion.  We'll build
 * up a string and pass it to our -openString:, which wants things like
 * "printf(3) ls pwd".
 */
@interface ManOpenURLHandlerCommand : NSScriptCommand

@end
