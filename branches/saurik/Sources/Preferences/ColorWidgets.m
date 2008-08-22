#import "ColorWidgets.h"

@implementation ColorButton

- (id)initWithFrame:(CGRect)frame colorRef:(RGBAColorRef)c
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:colorWithRGBA(1,1,1,0)];
        colorRef = c;
    }
    return self;
}

- (RGBAColor)color 
{
    return *colorRef;
}

- (void)setColorRef:(RGBAColorRef)cref
{
    colorRef = cref;
    [self setNeedsDisplay];  
}

- (void)drawRect:(struct CGRect)rect
{
    CGContextRef context = UICurrentContext();
    CGContextSetFillColorWithColor(context, CGColorWithRGBAColor([self color]));
    CGContextSetStrokeColorWithColor(context, colorWithRGBA(0.5,0.5,0.5,1));

    UIBezierPath *path = [UIBezierPath roundedRectBezierPath:CGRectMake(2, 2, rect.size.width-4, rect.size.height-4)
                                           withRoundedCorners:0xffffffff
                                             withCornerRadius:7.0f];	 

    [path fill];
    [path stroke];

    CGContextFlush(context);  
}

- (void)colorChanged:(NSArray *)colorValues
{
    *colorRef = RGBAColorMakeWithArray(colorValues);
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
    CGContextSetFillColorWithColor(context, CGColorWithRGBAColor(color));
    CGContextSetStrokeColorWithColor(context, colorWithRGBA(0.0,0.0,0.0,0.8));

    UIBezierPath *path = [UIBezierPath roundedRectBezierPath:CGRectMake(10, 2, rect.size.width-20, rect.size.height-4)
                                           withRoundedCorners:0xffffffff
                                             withCornerRadius:7.0f];	 

    [path fill];
    [path stroke];

    CGContextFlush(context);  
}

- (void)setColor:(RGBAColor)color_
{
    color = color_;
    [self setNeedsDisplay];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
