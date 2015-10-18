#import <Foundation/Foundation.h>
#import <LUMI/LUMI-Swift.h>

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    LUMIHardware *hardware = [LUMIHardware new];

    CFRunLoopRun();
  }
  return 0;
}
