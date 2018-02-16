//
//  PoofDragTableView.m
//  ManOpen
//
//  Created by Don McCaughey on 2/15/18.
//

#import "PoofDragTableView.h"

#import "NSObject+PoofDragDataSource.h"
#import "SystemType.h"


#define SessionSlideBackKey @"animatesToStartingPositionsOnCancelOrFail"


@implementation PoofDragTableView

- (BOOL)containsScreenPoint:(NSPoint)screenPoint
{
    NSRect screenRect = {
        .origin=screenPoint,
    };
    NSRect windowRect = [self.window convertRectFromScreen:screenRect];
    NSPoint viewPoint = [self convertPoint:windowRect.origin fromView:nil];
    
    return NSMouseInRect(viewPoint, [self bounds], [self isFlipped]);
}

- (void)dragImage:(NSImage *)anImage at:(NSPoint)imageLoc offset:(NSSize)mouseOffset event:(NSEvent *)theEvent pasteboard:(NSPasteboard *)pboard source:(id)sourceObject slideBack:(BOOL)slideBack
{
    /* Prevent slide back prior to Lion (where we can control it with newer methods) */
    [super dragImage:anImage at:imageLoc offset:mouseOffset event:theEvent pasteboard:pboard source:sourceObject slideBack:IsLion() && slideBack];
}

/* Only implement the 10.7 method, since I don't think we can conditionally affect the "slide back" value prior to 10.7 */
- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint
{
    //    [super draggingSession:session movedToPoint:screenPoint]; // doesn't exist
    [session setValue:[NSNumber numberWithBool:[self containsScreenPoint:screenPoint]] forKey:SessionSlideBackKey];
}

/* 10.7 has a new method, but it still calls this one, so this is all we need */
- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation
{
    /* Only try the poof if the operation was None (nothing accepted the drop) and it is outside our view */
    if (operation == NSDragOperationNone && ![self containsScreenPoint:screenPoint])
    {
        if ([[self dataSource] respondsToSelector:@selector(tableView:performDropOutsideViewAtPoint:)] &&
            [(id)[self dataSource] tableView:self performDropOutsideViewAtPoint:screenPoint])
        {
            NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, screenPoint, NSZeroSize, nil, nil, nil);
        }
    }
    [super draggedImage:anImage endedAt:screenPoint operation:operation];
}

@end
