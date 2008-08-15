#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Color.h"

@interface ColorButton : UIView
{
    RGBAColorRef colorRef;
}

- (id)initWithFrame:(CGRect)frame colorRef:(RGBAColorRef)c;
- (void)colorChanged:(NSArray *)colorValues;
- (void)setColorRef:(RGBAColorRef)colorRef;

@end

@interface ColorTableCell : UIPreferencesTableCell
{
    RGBAColor color;
}

- (void)setColor:(RGBAColor)color;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
