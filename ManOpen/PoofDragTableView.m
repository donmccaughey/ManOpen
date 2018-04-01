//
//  PoofDragTableView.m
//  ManOpen
//
//  Created by Don McCaughey on 2/15/18.
//

#import "PoofDragTableView.h"

#import "NSObject+PoofDragDataSource.h"
#import "SystemType.h"


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

- (void)draggingSession:(NSDraggingSession *)session
           movedToPoint:(NSPoint)screenPoint
{
    session.animatesToStartingPositionsOnCancelOrFail = [self containsScreenPoint:screenPoint];
}

- (void)draggingSession:(NSDraggingSession *)session
           endedAtPoint:(NSPoint)screenPoint
              operation:(NSDragOperation)operation
{
    if (NSDragOperationNone != operation) return;
    if ([self containsScreenPoint:screenPoint]) return;
    if (![self.dataSource respondsToSelector:@selector(tableView:performDropOutsideViewAtPoint:)]) return;
    if (![(id)self.dataSource tableView:self performDropOutsideViewAtPoint:screenPoint]) return;
    
    NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, screenPoint, NSZeroSize, nil, nil, nil);
}

@end
