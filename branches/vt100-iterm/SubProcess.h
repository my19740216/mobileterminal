// SubProcess.h
#include <Foundation/Foundation.h>

@interface SubProcess : NSObject
{
  int _fd;
}

- (id)initWithWidth:(int)width Height:(int)height;
- (int)fileDescriptor;
- (void)dealloc;

@end
