//
//  Color.m
//  Terminal

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

#import "Color.h"

UIColor *colorWithRGBA(float red, float green, float blue, float alpha)
{
	return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation UIColor(ArraySupport)

+ (UIColor *)colorWithArray:(NSArray *)array
{
    return [UIColor colorWithRed:MIN(MAX(0, [[array objectAtIndex:0] floatValue]), 1)
                           green:MIN(MAX(0, [[array objectAtIndex:1] floatValue]), 1)
                            blue:MIN(MAX(0, [[array objectAtIndex:2] floatValue]), 1)
                           alpha:MIN(MAX(0, [[array objectAtIndex:3] floatValue]), 1)];
}

@end

//_______________________________________________________________________________
//_______________________________________________________________________________

@implementation NSArray(ColorSupport)

+ (NSArray *)arrayWithColor:(UIColor *)color
{
    size_t num = CGColorGetNumberOfComponents([color CGColor]);
    const CGFloat * vals = CGColorGetComponents([color CGColor]);

    NSArray *colorArray = nil;
    if (num == 2) {
        // Grayscale (white and alpha components)
        colorArray = [NSArray arrayWithObjects:
           [NSNumber numberWithFloat:vals[0]],
           [NSNumber numberWithFloat:vals[0]],
           [NSNumber numberWithFloat:vals[0]],
           [NSNumber numberWithFloat:vals[1]],
           nil];
    } else {
        // Assume RGBA (as we don not use CMYK) 
        colorArray = [NSArray arrayWithObjects:
           [NSNumber numberWithFloat:vals[0]],
           [NSNumber numberWithFloat:vals[1]],
           [NSNumber numberWithFloat:vals[2]],
           [NSNumber numberWithFloat:vals[3]],
           nil];
    }

    return colorArray;
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
