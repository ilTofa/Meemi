//
//  Meemi.h
//  Meemi
//
//  Created by Giacomo Tufano on 18/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Meme.h"
#import "User.h"

@class ASINetworkQueue;

@protocol MeemiDelegate;

typedef enum {
	MmRValidateUser = 1,
	MmRPostImage,
	MmRPostText,
	MmGetNew,
	MmMarkNewRead,
	MmGetNewUsers,
	MMGetNewPvt,
	MMGetNewPvtSent,
	MMGetNewUser,
	MMFollowUnfollow
} MeemiRequest;

typedef enum
{
	MmUserExists = 0,
	MmWrongKey = 1,
	MmWrongPwd = 2,
	MmUserNotExists = 3,
	MmWrongMeme_type = 4,
	MmNoRecipientForPrivateMeme = 5,
	MmNoReplyAllowed = 6,
	MmPostOK = 7,
	MmNotLoggedIn = 8,
	MmMarked = 9,
	MmAddedToFavs = 10,
	MmDeletedFromFavs = 11,
	MmChanged = 12,
	MmNotYours = 13,
	MmMemeRemoved = 14,
	MmMemeDoNotExists = 15,
	MmFollowOK = 17,
	MmUnfollowOK = 19,
	MmOperationOK = 998,
	MmUndefinedError = 999
} MeemiResult;

// Notification posted
#define kGotLocation @"gotLocation"
#define kNowBusy @"nowBusy"
#define kNowFree @"nowFree"

/* #define kMeemiDatesFormat @"EEE, dd MMM yyyy HH:mm:ss ZZZ" */
#define kMeemiDatesFormat @"dd MMM yyyy HH:mm:ss ZZZ"

@interface Meemi : NSObject <CLLocationManagerDelegate, NSXMLParserDelegate>
{
	BOOL valid;
	NSString *screenName, *password;
	id<MeemiDelegate> delegate;
	MeemiRequest currentRequest;
	
	// for use by NSXMLParser and its delegates
	NSXMLParser *addressParser;
	NSMutableString *currentStringValue;
	NSMutableData *xmlData;

	// CoreData hook
	NSManagedObjectContext *managedObjectContext;
	
	// Next three contain the current one
	Meme *theMeme;
	User *theUser;

	NSURLConnection *theReverseGeoConnection;
	// How Many times have been denied Location use?
	double distance;
	BOOL needLocation, needG13N;
	CLLocationManager *locationManager;
	int nLocationUseDenies;
	BOOL lcDenied;	
	NSString *placeName, *state;
	NSString *nearbyPlaceName;
	
	// mark how many records we got.
	int howMany;
	int howManyRequestTotal;
	int newMemesPageWatermark;
	// Temporary workaround for no "mark read" bug of meemi
	BOOL currentMemeIsNew;
	// Accumulator for recipient of private memes
	NSMutableString *sent_to;
	// Maintain "last meme read" number (for use by updateQtaReply)
	NSNumber *newMemeID; 
	// limits on number and timing of new memes reads
	int memeNumber;
	int memeTime;
	// last date
	NSDate *lastMemeTimestamp;
	NSDate *lastReadDate;

	NSMutableArray *newUsersQueue;
	
	// The Queue
	ASINetworkQueue *networkQueue;
	NSOperationQueue *theQueue;
	
	// Is the channel available?
	BOOL busy;	
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign, getter=isLCDenied) BOOL lcDenied;
@property (nonatomic, assign) int nLocationUseDenies;
@property (nonatomic, assign) int memeNumber;
@property (nonatomic, assign) int memeTime;
@property (nonatomic, retain) NSDate *lastReadDate;
@property (nonatomic, getter=isValid) BOOL valid;
@property (nonatomic, copy) NSString *nearbyPlaceName;
@property (nonatomic, copy) NSString *screenName;
@property (nonatomic, copy) NSString *password;
@property (assign) id<MeemiDelegate> delegate;
@property (assign) MeemiRequest currentRequest;
@property (nonatomic, retain) NSString *placeName, *state;
@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic, assign, getter=isBusy) BOOL busy;

+(Meemi *)sharedSession;

- (void)startLocation;
- (void)stopLocation;

-(void)startSessionFromUserDefaults;

-(NSString *)getResponseDescription:(MeemiResult)response;
-(void)validateUser:(NSString *) meemi_id usingPassword:(NSString *)pwd;
-(void)postImageAsMeme:(UIImage *)image withDescription:(NSString *)description withLocalization:(BOOL)canBeLocalized;
-(void)postImageAsReply:(UIImage *)image withDescription:(NSString *)description withLocalization:(BOOL)canBeLocalized replyWho:(NSString *)replyScreenName replyNo:(NSNumber *)replyID;
-(void)postTextAsMeme:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized;
-(void)postTextReply:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized replyWho:(NSString *)replyScreenName replyNo:(NSNumber *)replyID;
-(void)getNewMemes:(BOOL)fromScratch;
-(void)getNewPrivateMemes:(BOOL)fromScratch;
-(void)getNewPrivateMemesSent:(BOOL)fromScratch;
-(void)markNewMemesRead;
-(void)markMemeRead:(NSNumber *)memeID;
-(void)markMemeSpecial:(NSNumber *)memeID;
-(void)getUser:(NSString *)withName;
-(void)followUser:(NSString *)user;
-(void)unfollowUser:(NSString *)user;

-(BOOL)parse:(NSData *)responseData;
-(void)updateAvatars;
-(BOOL)isMemeAlreadyExisting:(NSNumber *)memeID;

@end

@protocol MeemiDelegate

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error;
-(void)meemi:(MeemiRequest)request didFinishWithResult:(MeemiResult)result;

@end
