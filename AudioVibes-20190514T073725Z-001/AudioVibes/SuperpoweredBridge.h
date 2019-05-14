//
//  SuperpoweredBridge.h
//  AudioVibes
//  The public Objective-C++ stuff we expose to Swift.
//

#import <Foundation/Foundation.h>

@interface Superpowered: NSObject

- (void)getMagnitudes:(float *)freqs;
- (void)stopPlayback;

@end
