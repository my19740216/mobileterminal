/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "GSAttributedString.h"
#import "GSMutableAttributedString.h"
#import "GSAttributedString_placeholder.h"
//#import <Foundation/Foundation.h>

NSString *GSBackgroundColorAttributeName = @"bgcolor";
NSString *GSForegroundColorAttributeName = @"fgcolor";
NSString *GSUnderlineStyleAttributeName = @"underline";

@implementation GSAttributedString

+allocWithZone:(NSZone *)zone {
   if(self==[GSAttributedString class])
    return NSAllocateObject([GSAttributedString_placeholder class],0,NULL);

   return NSAllocateObject(self,0,zone);
}

-init {
   return [self initWithString:@""];
}

-initWithString:(NSString *)string {
   //[NSException raise: NSInvalidAbstractInvocation format: @"", nil];
    return nil;
}

-initWithString:(NSString *)string attributes:(NSDictionary *)attributes {
   //[NSException raise: NSInvalidAbstractInvocation format: @"", nil];
    return nil;
}

-initWithAttributedString:(GSAttributedString *)other {
   //[NSException raise: NSInvalidAbstractInvocation format: @"", nil];
    return nil;
}

-copy {
   return [self retain];
}

-copyWithZone:(NSZone *)zone {
   return [self retain];
}

-mutableCopy {
   return [(GSMutableAttributedString *)[GSMutableAttributedString allocWithZone:NULL] initWithAttributedString:self];
}

-mutableCopyWithZone:(NSZone *)zone {
   return [(GSMutableAttributedString *)[GSMutableAttributedString allocWithZone:zone] initWithAttributedString:self];
}

-(BOOL)isEqualToAttributedString:(GSAttributedString *)other {
   //[NSException raise: NSUnimplementedMethod format: @"", nil];
   return NO;
}

-(unsigned)length {
   return [[self string] length];
}

-(NSString *)string {
   //[NSException raise: NSInvalidAbstractInvocation format: @"", nil];
   return nil;
}

-(NSDictionary *)attributesAtIndex:(unsigned)location effectiveRange:(NSRangePointer)range {
   //[NSException raise: NSInvalidAbstractInvocation format: @"", nil];
   return nil;
}

-(NSDictionary *)attributesAtIndex:(unsigned)location
   longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)inRange {
   //NSUnimplementedMethod();
   return nil;
}

-attribute:(NSString *)name atIndex:(unsigned)location
   effectiveRange:(NSRangePointer)range {
   return [[self attributesAtIndex:location effectiveRange:range] objectForKey:name];
}

-attribute:(NSString *)name atIndex:(unsigned)location
   longestEffectiveRange:(NSRangePointer)range inRange:(NSRange)inRange {
   //NSUnimplementedMethod();
   return nil;
}

-(GSAttributedString *)attributedSubstringFromRange:(NSRange)range {
   GSMutableAttributedString *result=[[[GSMutableAttributedString alloc] init] autorelease];
   unsigned  location=range.location;
   unsigned  limit=NSMaxRange(range);

   while(location<limit){
    NSRange         effectiveRange,appendedRange;
    NSDictionary   *attributes=[self attributesAtIndex:location effectiveRange:&effectiveRange];

    if(effectiveRange.location<location){
     effectiveRange.length=NSMaxRange(effectiveRange)-location;
     effectiveRange.location=location;
    }
    if(NSMaxRange(effectiveRange)>limit)
     effectiveRange.length=limit-effectiveRange.location;

    appendedRange.location=[result length];
    appendedRange.length=effectiveRange.length;
    [[result mutableString] appendString:[[self string] substringWithRange:effectiveRange]];
    [result setAttributes:attributes range:appendedRange];

    location=NSMaxRange(effectiveRange);
   }
   return result;
}

@end
