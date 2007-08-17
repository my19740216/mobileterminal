/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

// Original - Christopher Lloyd <cjwl@objc.net>
#import "GSTextStorage_concrete.h"
//#import <AppKit/NSNibKeyedUnarchiver.h>
#import "Debug.h"

@implementation GSTextStorage_concrete

-initWithString:(NSString *)string {
   [super initWithString:string];
   _string=[string mutableCopy];
   _rangeToAttributes=NSCreateRangeToCopiedObjectEntries(0);
   NSRangeEntryInsert(_rangeToAttributes,NSMakeRange(0,[_string length]),[NSDictionary dictionary]);
   return self;
}

-(void)dealloc {
   [_string release];
   NSFreeRangeEntries(_rangeToAttributes);
   [super dealloc];
}

-(NSString *)string {
   return _string;
}

-(NSDictionary *)attributesAtIndex:(unsigned)location
   effectiveRange:(NSRangePointer)effectiveRangep {
   NSDictionary *result;

   if(location>=[self length])
    [NSException raise: NSRangeException format:@"index %d beyond length %d",location,[self length]];

   if((result=NSRangeEntryAtIndex(_rangeToAttributes,location,effectiveRangep))==nil)
    result=[NSDictionary dictionary];

   if(effectiveRangep!=NULL && effectiveRangep->length==NSNotFound)
    effectiveRangep->length=[self length]-effectiveRangep->location;

   return result;
}

static inline int replaceCharactersInRangeWithString(GSTextStorage_concrete *self,NSRange range,NSString *string){
   int delta=[string length]-range.length;

   [self->_string replaceCharactersInRange:range withString:string];

//GSRangeEntriesDump(self->_rangeToAttributes);

   GSRangeEntriesExpandAndWipe(self->_rangeToAttributes,range,delta);
   if(NSCountRangeEntries(self->_rangeToAttributes)==0)
    NSRangeEntryInsert(self->_rangeToAttributes,NSMakeRange(0,[self->_string length]),[NSDictionary dictionary]);

GSRangeEntriesVerify(self->_rangeToAttributes,[self length]);

   return delta;
}

static inline void setAttributes(GSTextStorage_concrete *self,NSDictionary *attributes,NSRange range){
   if(attributes==nil)
    attributes=[NSDictionary dictionary];

   if([self->_string length]==0){
    NSResetRangeEntries(self->_rangeToAttributes);
    NSRangeEntryInsert(self->_rangeToAttributes,range,attributes);
   }
   else if(range.length>0){
    GSRangeEntriesDivideAndConquer(self->_rangeToAttributes,range);
    NSRangeEntryInsert(self->_rangeToAttributes,range,attributes);
   }

GSRangeEntriesVerify(self->_rangeToAttributes,[self length]);

}

static inline void replaceCharactersInRangeWithAttributedString(GSTextStorage_concrete *self,NSRange replaced,GSAttributedString *other) {
    NSString *string=[other string];
   unsigned location=0;
   unsigned limit=[string length];
   int      delta=replaceCharactersInRangeWithString(self,replaced,string);
   
   [self edited:GSTextStorageEditedAttributes|GSTextStorageEditedCharacters range:replaced changeInLength:delta];
   
   while(location<limit){
    NSRange       effectiveRange;
    NSDictionary *attributes=[other attributesAtIndex:location effectiveRange:&effectiveRange];
    NSRange       range=NSMakeRange(replaced.location+location,effectiveRange.length);

    setAttributes(self,attributes,range);
    
    location=NSMaxRange(effectiveRange);
   }

   [self edited:GSTextStorageEditedAttributes range:NSMakeRange(replaced.location,limit) changeInLength:0];
}

-(void)replaceCharactersInRange:(NSRange)range withString:(NSString *)string {
   int delta=replaceCharactersInRangeWithString(self,range,string);
   [self edited:GSTextStorageEditedAttributes|GSTextStorageEditedCharacters range:range changeInLength:delta];
}

-(void)setAttributes:(NSDictionary *)attributes range:(NSRange)range {
   setAttributes(self,attributes,range);
   [self edited:GSTextStorageEditedAttributes range:range changeInLength:0];
}

-(void)replaceCharactersInRange:(NSRange)replaced withAttributedString:(GSAttributedString *)other {
   replaceCharactersInRangeWithAttributedString(self,replaced,other);
}

-(void)setAttributedString:(GSAttributedString *)attributedString {
   [self beginEditing];
   replaceCharactersInRangeWithAttributedString(self,NSMakeRange(0,[self length]),attributedString);
   [self endEditing];
}

-(NSMutableString *)mutableString {
   return [[[NSClassFromString(@"NSMutableString_proxyToMutableAttributedString") allocWithZone:NULL] performSelector:@selector(initWithMutableAttributedString:) withObject:self] autorelease];
}

-(void)fixAttributesAfterEditingRange:(NSRange)range {
}

@end
