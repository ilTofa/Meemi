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

	// CoreData hook
	NSManagedObjectContext *managedObjectContext;
	
	// Next three contain the current one
	Meme *theMeme;
	User *theUser;

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
	// Workaround <replies> data
	NSNumber *replyTo;
	NSString *replyUser;

	NSMutableArray *newUsersQueue;
	
	// The Queue
	ASINetworkQueue *networkQueue;
	NSOperationQueue *theQueue;
	
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (assign) id<MeemiDelegate> delegate;
@property (assign) MeemiRequest currentRequest;
@property (retain) ASINetworkQueue *networkQueue;
@property (nonatomic, retain) NSNumber *replyTo;
@property (nonatomic, retain) NSString *replyUser;

// Main entry point
+(Meemi *)sharedSession;

// Location manager
- (void)startLocation;
- (void)stopLocation;

// Get description of return code
-(NSString *)getResponseDescription:(MeemiResult)response;

// Post memes (requires a valid session)
-(void)postImageAsMeme:(UIImage *)image withDescription:(NSString *)description withLocalization:(BOOL)canBeLocalized;
-(void)postImageAsReply:(UIImage *)image withDescription:(NSString *)description withLocalization:(BOOL)canBeLocalized replyWho:(NSString *)replyScreenName replyNo:(NSNumber *)replyID;
-(void)postTextAsMeme:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized;
-(void)postTextReply:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized replyWho:(NSString *)replyScreenName replyNo:(NSNumber *)replyID;
-(void)postTextAsPrivateMeme:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized privateTo:(NSString *)privateTo;

// Get Memes (requires a valid session)
-(void)getNewMemes:(BOOL)fromScratch;
-(void)getNewMemesRepliesOf:(NSNumber *)memeID screenName:(NSString *)user from:(int)startMeme number:(int)nMessagesToRetrieve;
-(void)getNewPrivateMemes:(BOOL)fromScratch;
-(void)getNewPrivateMemesSent:(BOOL)fromScratch;

// Memes state marking
-(void)markNewMemesRead;
-(void)markThreadRead:(NSNumber *)memeID;
-(void)markMemeRead:(NSNumber *)memeID;
-(void)markMemeSpecial:(NSNumber *)memeID;

// User management
-(void)loadAvatar:(NSString *)screen_name;
-(void)getUser:(NSString *)withName;
-(void)followUser:(NSString *)user;
-(void)unfollowUser:(NSString *)user;

// Private methods
-(BOOL)parse:(NSData *)responseData;
-(void)updateAvatars;
-(BOOL)isMemeAlreadyExisting:(NSNumber *)memeID;

@end

@protocol MeemiDelegate

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error;
-(void)meemi:(MeemiRequest)request didFinishWithResult:(MeemiResult)result;

@end
