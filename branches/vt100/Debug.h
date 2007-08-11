#import <stdio.h>

#define DEBUG(fmt,args...) printf(fmt, ## args); fflush(stdout);

