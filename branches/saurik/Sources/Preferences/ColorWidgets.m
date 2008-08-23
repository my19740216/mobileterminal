#import "ColorWidgets.h"

@implementation ColorButton

- (id)initWithFrame:(CGRect)frame colorRef:(UIColor **)c
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor clearColor]];
        colorRef = c;
    }
    return self;
}

- (UIColor *)color 
{
    return *colorRef;
}

- (void)setColor:(UIColor *)color
{
    if (*colorRef != color) {
        [*colorRef release];
        *colorRef = [color retain];
    }
}

- (void)setColorRef:(UIColor **)cref
{
    colorRef = cref;
    [self setNeedsDisplay];  
}

- (void)drawRect:(struct CGRect)rect
{
    CGContextRef context = UICurrentContext();
    CGContextSetFillColorWithColor(context, [[self color] CGColor]);
    CGContextSetStrokeColorWithColor(context, [colorWithRGBA(0.5,0.5,0.5,1) CGColor]);

    UIBezierPath *path = [UIBezierPath roundedRectBezierPath:CGRectMake(2, 2, rect.size.width-4, rect.size.height-4)
                                           withRoundedCorners:0xffffffff
                                             withCornerRadius:7.0f];	 

    [path fill];
    [path stroke];

    CGContextFlush(context);  
}

- (void)colorChanged:(NSArray *)colorValues
{
    [self setColor:[UIColor colorWithArray:colorValues]];
    [self setNeedsDisplay];
}

- (void)view:(UIView *)view handleTapWithCount:(int)count event:(id)event 
{
#if 0 // FIXME
    PreferencesController *prefs = [PreferencesController sharedInstance];
    [[prefs colorView] setColor:[self color]];
    [[prefs colorView] setDelegate:self];
    [prefs pushViewControllerWithView:[prefs colorView] navigationTitle:[[self superview] title]];
#endif
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation ColorTableCell

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UICurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextSetStrokeColorWithColor(context, [colorWithRGBA(0.0,0.0,0.0,0.8) CGColor]);

    UIBezierPath *path = [UIBezierPath roundedRectBezierPath:CGRectMake(10, 2, rect.size.width-20, rect.size.height-4)
                                           withRoundedCorners:0xffffffff
                                             withCornerRadius:7.0f];	 

    [path fill];
    [path stroke];

    CGContextFlush(context);  
}

- (void)setColor:(UIColor *)color_
{
    if (color != color_) {
        [color release];
        color = [color_ retain];
        [self setNeedsDisplay];
    }
}

- (void)dealloc
{
    [color release];
    [super dealloc];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
