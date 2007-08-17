/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "GSAttributedString.h"
#import "GSAttributedString_placeholder.h"
#import "GSAttributedString_nilAttributes.h"
#import "GSAttributedString_oneAttribute.h"
#import "GSAttributedString_manyAttributes.h"

@implementation GSAttributedString_placeholder

-(id)initWithString:(NSString *)string {
   NSDeallocateObject(self);

   return [(GSAttributedString_nilAttributes *)NSAllocateObject([GSAttributedString_nilAttributes class],0,NULL) initWithString:string];
}

-(id)initWithString:(NSString *)string attributes:(NSDictionary *)attributes {
   NSDeallocateObject(self);

   return [(GSAttributedString_oneAttribute *)NSAllocateObject([GSAttributedString_oneAttribute class],0,NULL) initWithString:string attributes:attributes];
}

-(id)initWithAttributedString:(GSAttributedString *)other {
   NSDeallocateObject(self);

   return [(GSAttributedString_manyAttributes *)NSAllocateObject([GSAttributedString_manyAttributes class],0,NULL) initWithAttributedString:other];
}

@end
