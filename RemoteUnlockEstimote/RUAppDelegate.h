//
//  RUAppDelegate.h
//  RemoteUnlockEstimote
//
//  Created by Kamil Trzciński on 30/11/13.
//  Copyright (c) 2013 Polidea. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "RUWindow.h"

@interface RUAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet RUWindow *window;

@end
