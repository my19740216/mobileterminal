/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "NSAttributedString.h"
#import "NSMutableAttributedString.h"
#import "NSAttributedString_placeholder.h"
#import <Foundation/Foundation.h>

NSString *NSBackgroundColorAttributeName = @"bgcolor";
NSString *NSForegroundColorAttributeName = @"fgcolor";
NSString *NSUnderlineStyleAttributeName = @"underline";

@implementation NSAttributedString

+allocWithZone:(NSZone *)zone {
   if(self==[NSAttributedString class])
    return NSAllocateObject([NSAttributedString_placeholder class],0,NULL);

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

-initWithAttributedString:(NSAttributedString *)other {
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
   return [[NSMutableAttributedString allocWithZone:NULL] initWithAttributedString:self];
}

-mutableCopyWithZone:(NSZone *)zone {
   return [[NSMutableAttributedString allocWithZone:zone] initWithAttributedString:self];
}

-(BOOL)isEqualToAttributedString:(NSAttributedString *)other {
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

-(NSAttributedString *)attributedSubstringFromRange:(NSRange)range {
   NSMutableAttributedString *result=[[[NSMutableAttributedString alloc] init] autorelease];
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
