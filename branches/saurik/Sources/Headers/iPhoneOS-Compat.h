/**
 * iPhoneOS 1.1.x/2.x Compatibility
 */

// ---------------------------------------------------------- extended classes

@interface NSObject (iPhoneOS)
- (CGColorRef) cgColor;
- (CGColorRef) CGColor;
- (void) set;
@end

@implementation NSObject (iPhoneOS)

- (CGColorRef)cgColor
{
    return [self CGColor];
}

- (CGColorRef)CGColor
{
    return (CGColorRef) self;
}

- (void) set
{
    [[[[objc_getClass("UICGColor") alloc] initWithCGColor:[self CGColor]] autorelease] set];
}

@end

/* vim: set syntax=objc sw=4 ts=4 sts=4 expandtab textwidth=80 ff=unix: */
