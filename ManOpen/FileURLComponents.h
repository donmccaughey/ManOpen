//
//  FileURLComponents.h
//  ManOpen
//
//  Created by Don McCaughey on 1/14/18.
//

#import <Foundation/Foundation.h>


@interface FileURLComponents : NSObject

@property (copy) NSString *host;
@property (copy) NSString *path;

@property (readonly) BOOL isAbsolute;
@property (readonly) BOOL isDirectory;
@property (readonly) BOOL isLocalhost;

- (instancetype)initWithHost:(NSString *)host
                     andPath:(NSString *)path;

- (instancetype)initWithURL:(NSURL *)url;

@end
