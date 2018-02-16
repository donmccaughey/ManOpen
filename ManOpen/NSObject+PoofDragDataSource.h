//
//  NSObject+PoofDragDataSource.h
//  ManOpen
//
//  Created by Don McCaughey on 2/15/18.
//

#import <Cocoa/Cocoa.h>


@interface NSObject (PoofDragDataSource)

- (BOOL)tableView:(NSTableView *)tableView performDropOutsideViewAtPoint:(NSPoint)screenPoint;

@end
