//
//  WorldView.m
//

#import "WorldView.h"
#import "ObservationHelpers.h"

@interface WorldView ()

@property (nonatomic, weak, readonly) UIScrollView *scrollView;
@property (nonatomic, weak) UIView *windowView;

@end

@implementation WorldView

- (instancetype) initWithScrollView:(UIScrollView *)scrollView
{
    self = [super init];
    if (self) {
        _scrollView = scrollView;
        [self setup];
    }
    return self;
}

- (void) setup
{
//    self.alpha = 0; // initially not visible since we're zoomed out all the way
    self.backgroundColor = UIColor.whiteColor;

    self.layer.borderColor = UIColor.grayColor.CGColor;
    self.layer.borderWidth = 1.0f;

    UIView *windowView = [[UIView alloc] initWithFrame:CGRectZero];
    windowView.layer.borderWidth = 1.0f;

    [self addSubview:windowView];
    self.windowView = windowView;

    // Color in windowView
    [self tintColorDidChange];

    self.userInteractionEnabled = YES;

    // HACK: Adding this dispatch_UI fixes an animation problem when you first enter a sheet
    // and then immediately open Snapshots and hit the jump button.
    // (The problem is that self.windowView started out with a CGRectZero frame,
    //  which was used as the animation start point).
    [self setupObservation];
}

- (void) setupObservation
{
//    UIScrollView *scrollView = self.scrollView;
//    if (scrollView) {
//        [self listenTo:scrollView keyPath:@"contentOffset" selector:@selector(updateWindow)];
//        [self listenTo:scrollView keyPath:@"zoomScale" selector:@selector(updateWindow)];
//    }
}

-(void)tintColorDidChange
{
    UIView *windowView = self.windowView;
    windowView.backgroundColor = [self.tintColor colorWithAlphaComponent:0.3f];
    windowView.layer.borderColor = [self.tintColor colorWithAlphaComponent:0.4f].CGColor;
}

- (void) updateWindow
{
    UIScrollView *scroll = _scrollView;
    if (!scroll)
        return;

    CGPoint off = scroll.contentOffset;
    CGSize mySize = self.frame.size;
    CGSize theirSize = scroll.contentSize;

    // When DocumentViewController loads, the contentSize of the scroll is initially CGSizeZero
    // No need to update window until a legitimate scroll has happened
    if(CGSizeEqualToSize(theirSize, CGSizeZero)) return;

    CGFloat t_x = (mySize.width / theirSize.width);
    CGFloat t_y = (mySize.height / theirSize.height);
    CGFloat x = off.x * t_x;
    CGFloat y = off.y * t_y;

    CGFloat w = scroll.bounds.size.width * t_x;
    CGFloat h = scroll.bounds.size.height *  t_y;

    self.windowView.frame = CGRectIntersection(CGRectMake(x, y, w, h), self.bounds);
}

@end
