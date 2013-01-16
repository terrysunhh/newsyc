//
//  BodyTextView.m
//  newsyc
//
//  Created by Grant Paul on 1/15/13.
//
//

#import "BodyTextView.h"

#import "HNObjectBodyRenderer.h"
#import "SharingController.h"

@interface BodyTextRenderView : UIView {
    __weak BodyTextView *bodyTextView;
}
@end

@implementation BodyTextRenderView

- (id)initWithBodyTextView:(BodyTextView *)bodyTextView_ {
    if ((self = [super init])) {
        bodyTextView = bodyTextView_;
    }

    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

	[bodyTextView drawContentView:rect];
}

@end

@implementation BodyTextView
@synthesize delegate, renderer;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        linkLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressFromRecognizer:)];
        [linkLongPressRecognizer setMinimumPressDuration:0.65f];
        [linkLongPressRecognizer setCancelsTouchesInView:NO];
        [self addGestureRecognizer:linkLongPressRecognizer];

        bodyTextRenderView = [[BodyTextRenderView alloc] initWithBodyTextView:self];
        [bodyTextRenderView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [bodyTextRenderView setFrame:CGRectInset([self bounds], -10.0f, -10.0f)];
        [bodyTextRenderView setBackgroundColor:[UIColor clearColor]];
        [bodyTextRenderView setClipsToBounds:NO];
        [self addSubview:bodyTextRenderView];

        [self setBackgroundColor:[UIColor clearColor]];
        [self setClipsToBounds:NO];
    }

    return self;
}

- (void)dealloc {
    [renderer release];
    [bodyTextRenderView release];

    [super dealloc];
}

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    [bodyTextRenderView setNeedsDisplay];
}

- (void)setRenderer:(HNObjectBodyRenderer *)renderer_ {
    [renderer autorelease];

    [self clearHighlights];

    renderer = [renderer_ retain];
    [self setNeedsDisplay];
}

- (void)drawContentView:(CGRect)rect {
    [renderer renderInContext:UIGraphicsGetCurrentContext() rect:CGRectInset([bodyTextRenderView bounds], 10.0, 10.0)];

    // draw link highlight
    UIBezierPath *highlightBezierPath = [UIBezierPath bezierPath];
    
    for (NSValue *rect in highlightedRects) {
        CGRect highlightedRect = CGRectIntegral([rect CGRectValue]);

        if (highlightedRect.size.width != 0 && highlightedRect.size.height != 0) {
            CGRect rect = CGRectInset(highlightedRect, -4.0f, -4.0f);
            rect.origin.x += 10.0f;
            rect.origin.y += 10.0f;

            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:3.0f];
            [highlightBezierPath appendPath:bezierPath];
        }
    }
    
    [[UIColor colorWithWhite:0.5f alpha:0.5f] set];
    [highlightBezierPath fill];
}

#pragma mark - Links

- (BOOL)linkHighlighted {
    return highlightedRects != nil;
}

- (void)clearHighlights {
    if (highlightedRects != nil) {
        [highlightedRects release];
        highlightedRects = nil;
        
        [self setNeedsDisplay];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self clearHighlights];

    UITouch *touch = [touches anyObject];
    CGPoint bodyPoint = [touch locationInView:self];
    [renderer linkURLAtPoint:bodyPoint forWidth:[self bounds].size.width rects:&highlightedRects];

    if (highlightedRects != nil) {
        [highlightedRects retain];

        [self setNeedsDisplay];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (highlightedRects != nil) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];

        NSURL *url = [renderer linkURLAtPoint:point forWidth:[self bounds].size.width rects:NULL];

        if (url != nil) {
            if ([delegate respondsToSelector:@selector(bodyTextView:selectedURL:)]) {
                [delegate bodyTextView:self selectedURL:url];
            }
        }
    }

    [self clearHighlights];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self clearHighlights];
}

- (void)longPressFromRecognizer:(UILongPressGestureRecognizer *)gesture {
	if ([gesture state] == UIGestureRecognizerStateBegan) {
        CGPoint point = [gesture locationInView:self];

        NSSet *rects;
        NSURL *url = [renderer linkURLAtPoint:point forWidth:[self bounds].size.width rects:&rects];

        if (url != nil && [rects count] > 0) {
            SharingController *sharingController = [[SharingController alloc] initWithURL:url title:nil fromController:nil];
            [sharingController showFromView:self atRect:CGRectInset(CGRectMake(point.x, point.y, 0, 0), -4.0f, -4.0f)];
            [sharingController release];
        }

        [self clearHighlights];
    }
}

@end
