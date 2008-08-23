#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "Color.h"

@interface ColorButton : UIView
{
    UIColor **colorRef;
}

- (id)initWithFrame:(CGRect)frame colorRef:(UIColor **)c;
- (void)colorChanged:(NSArray *)colorValues;
- (void)setColorRef:(UIColor **)colorRef;

@end

@interface ColorTableCell : UIPreferencesTableCell
{
    UIColor *color;
}

- (void)setColor:(UIColor *)color;

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
