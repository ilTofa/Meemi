//
//  AWindowThatDetectsShakes.m
//  Meemi
//
//  Created by Giacomo Tufano on 13/04/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "AWindowThatDetectsShakes.h"

// This is only to post a global notification when device is shaken...
// works because in MainWindow.xib the UIWindow is set to this one.

@implementation AWindowThatDetectsShakes

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event 
{
    if (event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake) 
		[[NSNotificationCenter defaultCenter] postNotificationName:@"deviceShaken" object:self];
}

@end
