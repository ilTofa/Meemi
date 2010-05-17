//
//  MeemiSession.m
//  Meemi
//
//  Created by Giacomo Tufano on 17/05/10.
//  Copyright 2010 Sun Microsystems Italia SpA. All rights reserved.
//

#import "MeemiSession.h"

@implementation MeemiSession

@synthesize screenName, password, lcDenied, nLocationUseDenies, valid, nearbyPlaceName, placeName, state, busy;
@synthesize memeNumber, memeTime, lastReadDate;

static MeemiSession *sharedSession = nil;

#pragma mark Singleton Class Setup

+(MeemiSession *)sharedSession
{
	@synchronized(self) {
        if (sharedSession == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedSession;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedSession == nil) {
            sharedSession = [super allocWithZone:zone];
            return sharedSession;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (unsigned)retainCount
{
    return UINT_MAX;  //denotes an object that cannot be released
}

- (void)release
{
    //do nothing
}

- (id)autorelease
{
    return self;
}

-(id) init
{
	if(self = [super init])
	{
		self.valid = NO;
		needLocation = YES;
		needG13N = YES;
		self.nearbyPlaceName = @"";
		// At the moment, user have not denied anything
		self.lcDenied = NO;
		// init the Queue
		theQueue = [[NSOperationQueue alloc] init];
		// mark ourselves not busy
		self.busy = NO;
		return self;
	}
	else
		return nil;
}

-(void)startSessionFromUserDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.screenName = [defaults stringForKey:@"screenName"];
	self.password = [defaults stringForKey:@"password"];
	self.memeNumber = [defaults integerForKey:@"rowNumber"];
	if(self.memeNumber == 0)
		self.memeNumber = 50;
	self.memeTime = [defaults integerForKey:@"memeTime"];
	if(self.memeTime == 0)
		self.memeTime = 24;
	// Last read meme...
	self.lastReadDate = [defaults objectForKey:@"lastRead"];
	// protect ourselves...
	if(self.lastReadDate == nil)
		self.lastReadDate = [NSDate distantPast];
	// get number of times user denied location use..
	self.nLocationUseDenies = [defaults integerForKey:@"userDeny"];
	self.valid = YES;
}

-(void)nowBusy
{
	self.busy++;
	if(self.busy)
	{
		DLog(@"Notified the world that we are now busy...");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kNowBusy object:self]];
	}
}

-(void)nowFree
{
	self.busy = (self.busy == 0) ? self.busy : self.busy - 1;
	if(self.busy == 0)
	{
		DLog(@"Notified the world that we are now free...");
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kNowFree object:self]];
	}
}

@end
