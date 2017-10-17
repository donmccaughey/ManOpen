
#import "NSData+Utils.h"
#import "SystemType.h"
#import <Foundation/NSException.h>
#import <libc.h>
#import <ctype.h>

@implementation NSData (Utils)

/*
 * Checks the data to see if it looks like the start of an nroff file.
 * Derived from logic in FreeBSD's file(1) command.
 */
- (BOOL)isNroffData
{
    const char *bytes = [self bytes];
    const char *ptr = bytes;

#define MATCH(str) (strncmp(ptr, str, strlen(str)) == 0)

    while (isspace(*ptr)) ptr++;

    /* Some X11R6 pages have a weird #pragma line at the start */
    if (MATCH("#pragma"))
    {
        const char *nextline = strchr(ptr, '\n');
        if (nextline != NULL) {
            ptr = nextline;
            while (isspace(*ptr)) ptr++;
        }
    }
            
    /* If not at the beginning of a line, bail. */
    if (!(ptr == bytes || *(ptr-1) == '\n' || *(ptr-1) == '\r')) return NO;


    /* Try for some common prefixes: .\", '\", '.\", \", and .\<sp> */
    if (MATCH(".\\\""))  return YES;
    if (MATCH("'\\\""))  return YES;
    if (MATCH("'.\\\"")) return YES;
    if (MATCH("\\\""))   return YES;
    if (MATCH(".\\ "))   return YES;
    if (MATCH("\\.\""))  return YES;  // found this on a joke man page

    /*
     * Now check for .[letter][letter], and .\" again.  In either case,
     * allow spaces after the '.'
     */
    if (*ptr == '.')
    {
        /* skip over '.' and whitespace */
        ptr++;
        while (isspace(*ptr)) ptr++;

        if (isalnum(ptr[0]) && isalnum(ptr[1])) return YES;
        if (ptr[0] == '\\'  && ptr[1] == '"')   return YES;
    }

    return NO;
}

- (BOOL)hasPrefixBytes:(void *)bytes length:(NSUInteger)len
{
    if ([self length] < len) return NO;
    return (memcmp([self bytes], bytes, (size_t)len) == 0);
}

- (BOOL)isRTFData
{
    char *header = "{\\rtf";
    return [self hasPrefixBytes:header length:strlen(header)];
}

- (BOOL)isGzipData
{
    return ([self hasPrefixBytes:"\037\235" length:2] ||    // compress(1) header
            [self hasPrefixBytes:"\037\213" length:2]);     // gzip(1) header
}

/* Very rough check -- see if more than a third of the first 100 bytes have the high bit set */
- (BOOL)isBinaryData
{
    NSUInteger checklen = MIN((NSUInteger)100, [self length]);
    NSUInteger i;
    NSUInteger badByteCount = 0;
    unsigned const char *bytes = [self bytes];

    if (checklen == 0) return NO;
    for (i=0; i<checklen; i++, bytes++)
        if (*bytes == '\0' || !isascii((int)*bytes)) badByteCount++;

    return (badByteCount > 0) && (checklen / badByteCount) <= 2;
}

@end

#import <sys/types.h>
#import <errno.h>
#import <assert.h>

@implementation NSFileHandle (Utils)

/*
 * The NSData -readDataToEndOfFile method does not deal with EINTR errors, which in most
 * cases is fine, but sometimes not when running under a debugger.  So... this is more to help
 * folks working on the code, rather the users ;-)
 */
- (NSData *)readDataToEndOfFileIgnoreInterrupt
{
    int fd = [self fileDescriptor];
    size_t offset = 0;
    size_t allocated = 16384;
    unsigned char *bytes = malloc(allocated);
    ssize_t bytesRead;
    
    do {
        if (offset >= allocated) {
            allocated *= 2;
            bytes = reallocf(bytes, allocated);
        }
        assert(bytes != NULL);

        do {
            bytesRead = read(fd, bytes + offset, allocated - offset);
        } while (bytesRead < 0 && ((errno == EINTR) || (errno == EAGAIN) || (errno == EWOULDBLOCK)));
        
        if (bytesRead > 0) {
            offset += bytesRead;
        }

    } while (bytesRead > 0);
    
    if (bytesRead < 0) {
        free(bytes);
        [NSException raise:NSFileHandleOperationException format:@"%s: %s", __FUNCTION__, strerror(errno)];
    }

    bytes = reallocf(bytes, offset);
    return [NSData dataWithBytesNoCopy:bytes length:(NSUInteger)offset];
}

@end
