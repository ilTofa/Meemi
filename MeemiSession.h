//
//  MeemiSession.h
//  Meemi
//
//  Created by Giacomo Tufano on 17/05/10.
//  Copyright 2010 Sun Microsystems Italia SpA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

// Notification posted
#define kGotLocation @"gotLocation"
#define kNowBusy @"nowBusy"
#define kNowFree @"nowFree"

// API key
#define kAPIKey @"dd51e68acb28da24c221c8b1627be7e69c577985"

@interface MeemiSession : NSObject 
{
	// Session data
	BOOL valid;
	NSString *screenName, *password;

	// Geolocalization data
	NSURLConnection *theReverseGeoConnection;
	// How Many times have been denied Location use?
	double distance;
	BOOL needLocation, needG13N;
	CLLocationManager *locationManager;
	int nLocationUseDenies;
	BOOL lcDenied;	
	NSString *placeName, *state;
	NSString *nearbyPlaceName;
	
	// limits on number and timing of new memes reads
	int memeNumber;
	int memeTime;
	// last date
	NSDate *lastMemeTimestamp;
	NSDate *lastReadDate;
		
	
	NSOperationQueue *theQueue;
	// Is the channel available?
	int busy;	
}

@property (nonatomic, assign) int memeNumber;
@property (nonatomic, assign) int memeTime;
@property (nonatomic, retain) NSDate *lastReadDate;
@property (nonatomic, copy) NSString *screenName;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, assign, getter=isLCDenied) BOOL lcDenied;
@property (nonatomic, assign) int nLocationUseDenies;
@property (nonatomic, getter=isValid) BOOL valid;
@property (nonatomic, copy) NSString *nearbyPlaceName;
@property (nonatomic, retain) NSString *placeName, *state;
@property (nonatomic, assign) int busy;

// Main entry point
+(MeemiSession *)sharedSession;

// Session init
-(void)startSessionFromUserDefaults;
-(void)validateUser:(NSString *) meemi_id usingPassword:(NSString *)pwd;

@end
