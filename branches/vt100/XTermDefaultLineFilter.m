//
//  XTermDefaultLineFilter.m
//  Crescat
//
//  Created by Fritz Anderson on Sun Nov 09 2003.
//  Copyright (c) 2003 Trustees of the University of Chicago. All rights reserved.
//

#import "XTermDefaultLineFilter.h"
#import "XTermEscapeLineFilter.h"
#import "XTermAltCharLineFilter.h"

@implementation XTermDefaultLineFilter

- (CharacterLineFilter *) escapeLineFilter { return [[XTermEscapeLineFilter alloc] initWithFallback: self]; }
- (CharacterLineFilter *) altCharLineFilter { return [[XTermAltCharLineFilter alloc] initWithFallback: self]; }

@end
