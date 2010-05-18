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
	MMGetNewReplies,
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

#ifdef __IPHONE_4_0
@interface Meemi : NSObject <CLLocationManagerDelegate, NSXMLParserDelegate>
#else
@interface Meemi : NSObject <CLLocationManagerDelegate>
#endif
{
	id<MeemiDelegate> delegate;
	MeemiRequest currentRequest;
	
	// for use by NSXMLParser and its delegates
	NSXMLParser *addressParser;
	NSMutableString *currentStringValue;
	NSMutableData *xmlData;

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

	// Workaround <replies> data
	NSNumber *replyTo;
	NSString *replyUser;

	NSMutableArray *newUsersQueue;
	
	// The Queue
	ASINetworkQueue *networkQueue;
	NSOperationQueue *theQueue;
}

@property (nonatomic, assign, getter=isLCDenied) BOOL lcDenied; //internal
@property (nonatomic, assign) int nLocationUseDenies; //internal
@property (nonatomic, assign) int memeNumber; 
@property (nonatomic, assign) int memeTime;
@property (nonatomic, retain) NSDate *lastReadDate;
@property (assign) id<MeemiDelegate> delegate;
@property (assign) MeemiRequest currentRequest;
@property (nonatomic, retain) NSString *placeName, *state;
@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic, retain) NSNumber *replyTo;
@property (nonatomic, retain) NSString *replyUser;

// Shared variables access methods
+(NSString *)password;
+(void)setPassword:(NSString *)newValue;
+(NSString *)screenName;
+(void)setScreenName:(NSString *)newValue;
+(BOOL)isValid;
+(NSManagedObjectContext *)managedObjectContext;
+(void)setManagedObjectContext:(NSManagedObjectContext *)newValue;
+(NSString *)nearbyPlaceName;
+(void)setNearbyPlaceName:(NSString *)newValue;

// is the session already active?
+(BOOL)isBusy;

// Not I/O bound methods
+(NSString *)getResponseDescription:(MeemiResult)response;

// Set various meme status into db
+(void)markNewMemesRead;
+(void)markThreadRead:(NSNumber *)memeID;
+(void)markMemeRead:(NSNumber *)memeID;
+(void)markMemeSpecial:(NSNumber *)memeID;

+(Meemi *)sharedSession;

- (void)startLocation;
- (void)stopLocation;

-(void)startSessionFromUserDefaults;

-(void)validateUser:(NSString *)meemi_id usingPassword:(NSString *)pwd;
-(void)postImageAsMeme:(UIImage *)image withDescription:(NSString *)description withLocalization:(BOOL)canBeLocalized;
-(void)postImageAsReply:(UIImage *)image withDescription:(NSString *)description withLocalization:(BOOL)canBeLocalized replyWho:(NSString *)replyScreenName replyNo:(NSNumber *)replyID;
-(void)postTextAsMeme:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized;
-(void)postTextReply:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized replyWho:(NSString *)replyScreenName replyNo:(NSNumber *)replyID;
-(void)postTextAsPrivateMeme:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized privateTo:(NSString *)privateTo;
-(void)getNewMemes:(BOOL)fromScratch;
-(void)getNewMemesRepliesOf:(NSNumber *)memeID screenName:(NSString *)user from:(int)startMeme number:(int)nMessagesToRetrieve;
-(void)getNewPrivateMemes:(BOOL)fromScratch;
-(void)getNewPrivateMemesSent:(BOOL)fromScratch;

-(void)loadAvatar:(NSString *)screen_name;
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
