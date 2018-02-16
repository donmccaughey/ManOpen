//
//  PoofDragTableView.h
//  ManOpen
//
//  Created by Don McCaughey on 2/15/18.
//

#import <Cocoa/Cocoa.h>


/*
 * Class to add a delegate method for when something was dropped with no other action
 * outside the view, i.e. the "poof" removing functionality.  In 10.7, this can almost
 * be implemented in the dataSource, but I wanted to retain the "slide back" functionality
 * when dropped in an invalid place inside the view, which requires a subclass anyways.
 * Prior to 10.7, a subclass is required to get the "end" notification, and also to
 * disable the "slide back" functionality.
 */
@interface PoofDragTableView : NSTableView

@end
