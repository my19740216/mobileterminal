/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

// an ordered, nonoverlapping set of NSRanges and related value
typedef struct GSRangeEntries GSRangeEntries;

typedef struct {
   GSRangeEntries *self;
   unsigned        index;
} NSRangeEnumerator;

FOUNDATION_EXPORT GSRangeEntries *NSCreateRangeToOwnedPointerEntries(unsigned capacity);
FOUNDATION_EXPORT GSRangeEntries *NSCreateRangeToCopiedObjectEntries(unsigned capacity);

FOUNDATION_EXPORT void NSFreeRangeEntries(GSRangeEntries *self);
FOUNDATION_EXPORT void  NSResetRangeEntries(GSRangeEntries *self);
FOUNDATION_EXPORT unsigned NSCountRangeEntries(GSRangeEntries *self);

FOUNDATION_EXPORT void  NSRangeEntryInsert(GSRangeEntries *self,NSRange range,void *value);
FOUNDATION_EXPORT void *NSRangeEntryAtIndex(GSRangeEntries *self,unsigned index,NSRange *effectiveRange);
FOUNDATION_EXPORT void *NSRangeEntryAtRange(GSRangeEntries *self,NSRange range);

FOUNDATION_EXPORT NSRangeEnumerator NSRangeEntryEnumerator(GSRangeEntries *self);
FOUNDATION_EXPORT BOOL NSNextRangeEnumeratorEntry(NSRangeEnumerator *state,NSRange *rangep,void **value);

FOUNDATION_EXPORT void GSRangeEntriesExpandAndWipe(GSRangeEntries *self,NSRange range,int delta);
FOUNDATION_EXPORT void GSRangeEntriesDivideAndConquer(GSRangeEntries *self,NSRange range);
FOUNDATION_EXPORT void GSRangeEntriesDump(GSRangeEntries *self);
FOUNDATION_EXPORT void GSRangeEntriesVerify(GSRangeEntries *self,unsigned length);
NSRange NSUnionRange2(NSRange r1, NSRange r2);

