//
//  Meemi.m
//  Meemi
//
//  Created by Giacomo Tufano on 18/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "Meemi.h"

#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"

#import "FlurryAPI.h"

// for SHA-256
#include <CommonCrypto/CommonDigest.h>

static Meemi *sharedSession = nil;

@implementation Meemi

@synthesize valid, screenName, password, delegate, currentRequest;
@synthesize lcDenied, nLocationUseDenies, nearbyPlaceName, placeName, state;
@synthesize managedObjectContext;
@synthesize networkQueue, busy;
@synthesize memeNumber, memeTime, lastReadDate;

#pragma mark Singleton Class Setup

+(Meemi *)sharedSession
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

#pragma mark ASIHTTPRequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	NSData *responseData = [request responseData];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.busy = NO;
	DLog(@"request sent and answer received. Calling parser for processing\n");
	[self parse:responseData];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.busy = NO;
	NSError *error = [request error];
	[self.delegate meemi:self.currentRequest didFailWithError:error];
}

#pragma mark Helpers

-(void)markSessionValid
{
	self.valid = YES;
}

-(void)startSessionFromUserDefaults
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.screenName = [defaults stringForKey:@"screenName"];
	self.password = [defaults stringForKey:@"password"];
	// TODO: should be read from defaults too
	self.memeNumber = [defaults integerForKey:@"rowNumber"];
	if(self.memeNumber == 0)
		self.memeNumber = 100;
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

// Parse response string
// returns YES if xml parsing succeeds, NO otherwise
- (BOOL) parse:(NSData *)responseData
{
//	DLog(@"Starting parse of: %@", responseData);
//	NSString *temp = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
//	DLog(@"As string: \"%@\"", temp);
    if (addressParser) // addressParser is an NSXMLParser instance variable
        [addressParser release];
	addressParser = [[NSXMLParser alloc] initWithData:responseData];
	[addressParser setDelegate:self];
    [addressParser setShouldResolveExternalEntities:YES];
    if([addressParser parse])
		return YES;
	else
		return NO;
}

-(void)setupMemeRelationshipsFrom:(NSString *)name
{
	DLog(@"Now in setupMemeRelationshipsFrom");
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	// We're looking for an User with this screen_name.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"screen_name like %@", name];
	[request setPredicate:predicate];
	// We're only looking for one.
	[request setFetchLimit:1];
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults != nil && [fetchResults count] != 0)
	{
		theUser = [fetchResults objectAtIndex:0];
		theAvatar = theUser.avatar;
		DLog(@"User %@ for the meme already existing: %@", name);
	}
	else
	{
		// Create an User and an Avatar and add them to the managedObjectContext
		// (and to the list of "new ones" for later processing
		theUser = (User *)[NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
		theUser.screen_name = name;
		theAvatar = (Avatar *)[NSEntityDescription insertNewObjectForEntityForName:@"Avatar" inManagedObjectContext:self.managedObjectContext];
		// set the relationship between theUser and theAvatar
		theAvatar.user = theUser;
		theUser.avatar = theAvatar;
		[newUsersFromNewMemes addObject:name];
		DLog(@"New user created for %@", name);
	}
	// Whatever theUser is (new or pre-existing) now it's time to set the relationship with theMeme
	theMeme.user = theUser;
	[theUser addMemeObject:theMeme];
	[request release];
}

-(BOOL)isMemeAlreadyExisting:(NSNumber *)memeID
{
	DLog(@"Now in isMemeAlreadyExisting");
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	// We're looking for an User with this screen_name.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Meme" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", memeID];
	[request setPredicate:predicate];
	// We're only looking for one.
	[request setFetchLimit:1];
	NSError *error;
	BOOL retValue;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults != nil && [fetchResults count] != 0)
		retValue = YES;
	else
		retValue = NO;
	[request release];
	return retValue;
}

-(void)updateQtaReply:(NSNumber *)repliesNumber
{
	DLog(@"Now in updateQtaReply");
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	// We're looking for an User with this screen_name.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Meme" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", newMemeID];
	[request setPredicate:predicate];
	// We're only looking for one.
	[request setFetchLimit:1];
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	if (fetchResults != nil && [fetchResults count] != 0)
	{
		Meme *theOldOne = [fetchResults objectAtIndex:0];
		if([theOldOne.qta_replies compare:repliesNumber] != NSOrderedSame)
		{
			DLog(@"Changing qta_replies on %@ from %@ to %@", newMemeID, theOldOne.qta_replies, repliesNumber);
			theOldOne.qta_replies = repliesNumber;
			theOldOne.new_replies = [NSNumber numberWithBool:YES];
		}
	}	
	[request release];
}

#pragma mark NSXMLParser delegate

// NSXMLParser delegates

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	// DEBUG: parse attributes
	DLog(@"Element Start: <%@>", elementName);
	NSEnumerator *enumerator = [attributeDict keyEnumerator];
	id key;
	while ((key = [enumerator nextObject])) 
	{
		DLog(@"attribute \"%@\" is \"%@\"", key, [attributeDict objectForKey:key]);
	}
	if([elementName isEqualToString:@"message"])
	{
		// If it was a request for user validation, check return and inform delegate
		if(self.currentRequest == MmRValidateUser)
		{
			NSString *code = [attributeDict objectForKey:@"code"];
			// Defensive code for the case "code" do not exists
			NSAssert(code, @"In NSXMLParser: attribute code for <message> is missing");
			// if user is OK. Save it (both class and NSUserDefaults).
			if([code intValue] == MmUserExists)
				[self markSessionValid];
			else // mark session not valid
				self.valid = NO;
			[self.delegate meemi:self.currentRequest didFinishWithResult:[code intValue]];
		}
		// If it was a  post, check return and inform delegate
		if(self.currentRequest == MmRPostImage || self.currentRequest == MmRPostText)
		{
			NSString *code = [attributeDict objectForKey:@"code"];
			// Defensive code for the case "code" do not exists
			NSAssert(code, @"In NSXMLParser: attribute code for <message> is missing");
			// if return code is OK, get back to delegate
			if([code intValue] == MmPostOK)
				[self.delegate meemi:self.currentRequest didFinishWithResult:[code intValue]];
		}
	}
	// parse memes
	if(self.currentRequest == MmGetNew)
	{
		// Zero meme count in reply, to start counting
		if([elementName isEqualToString:@"memes"])
			howMany = 0;
		// if a meme is coming increment meme count
		if([elementName isEqualToString:@"meme"])
		{
			howMany++;
			howManyRequestTotal++;
		}
	}
	if(self.currentRequest == MmGetUser)
	{
		if([elementName isEqualToString:@"info"])
		{
			NSString *name = [attributeDict objectForKey:@"screen_name"];
			ALog(@"Now looking for the user %@ for update", name);
			NSFetchRequest *request = [[NSFetchRequest alloc] init];
			// We're looking for an User with this screen_name.
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
			[request setEntity:entity];
			NSPredicate *predicate = [NSPredicate predicateWithFormat:@"screen_name like %@", name];
			[request setPredicate:predicate];
			// We're only looking for one.
			[request setFetchLimit:1];
			NSError *error;
			NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
			if (fetchResults != nil && [fetchResults count] != 0)
			{
				theUser = [fetchResults objectAtIndex:0];
				theUser.location = [attributeDict objectForKey:@"location"];
				theUser.real_name = [attributeDict objectForKey:@"real_name"];
				// Workaround stupid date
				NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
				NSString *tempDate = [NSString stringWithFormat:@"%@ +0200", [attributeDict objectForKey:@"since"]];
				theUser.since = [dateFormatter dateFromString:tempDate];
				[dateFormatter setDateFormat:@"yyyy-MM-dd"];
				theUser.birth = [dateFormatter dateFromString:[attributeDict objectForKey:@"birth"]];
			}
			else
			{
				NSAssert(YES, @"user not found while it should be present");
			}				
		}
		if([elementName isEqualToString:@"avatars"])
		{
			theUser.avatar.small = [[attributeDict objectForKey:@"small"] dataUsingEncoding:NSUTF8StringEncoding];
			theUser.avatar.medium = [[attributeDict objectForKey:@"medium"] dataUsingEncoding:NSUTF8StringEncoding];
			theUser.avatar.original = [[attributeDict objectForKey:@"normal"] dataUsingEncoding:NSUTF8StringEncoding];
		}
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	DLog(@"Data: %@", string);
    if (!currentStringValue)
        // currentStringValue is an NSMutableString instance variable
        currentStringValue = [[NSMutableString alloc] initWithCapacity:256];
    [currentStringValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	DLog(@"Element End: %@", elementName);
	DLog(@"<%@> fully received with value: <%@>", elementName, currentStringValue);

	// new_memes processing 
	if(self.currentRequest == MmGetNew)
	{
		// id received, verify if the meme is new.
		if([elementName isEqualToString:@"id"])
		{
			newMemeID = [NSNumber numberWithLongLong:[currentStringValue longLongValue]];
			currentMemeIsNew = ![self isMemeAlreadyExisting:newMemeID];
			if(currentMemeIsNew)
			{
				ALog(@"*** got a new meme");
				theMeme = (Meme *)[NSEntityDescription insertNewObjectForEntityForName:@"Meme" inManagedObjectContext:self.managedObjectContext];
				theMeme.id = newMemeID;
				theMeme.new_meme = [NSNumber numberWithBool:YES];
			}
			else
				ALog(@"*** Got an already read meme: %@", newMemeID);
		}
		// Other new memes things, only if the meme is new
		if(currentMemeIsNew)
		{
			// got a screen_name for a new meme. Setup relationship.
			if([elementName isEqualToString:@"screen_name"])
			{
				theMeme.screen_name = currentStringValue;
				[self setupMemeRelationshipsFrom:theMeme.screen_name];
			}
			if([elementName isEqualToString:@"date_time"])
			{
				NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:kMeemiDatesFormat];
				theMeme.date_time = [dateFormatter dateFromString:currentStringValue];
				[dateFormatter release];
			}
			if([elementName isEqualToString:@"dt_last_movement"])
			{
				NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:kMeemiDatesFormat];
				theMeme.dt_last_movement = [dateFormatter dateFromString:currentStringValue];
				[dateFormatter release];
			}
			if([elementName isEqualToString:@"meme_type"])
			{
				theMeme.meme_type = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				if(![theMeme.meme_type isEqualToString:@"text"])
					theMeme.content = [NSString stringWithFormat:@"This meme is a %@", theMeme.meme_type];
			}
			
			if([elementName isEqualToString:@"content"])
				theMeme.content = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([elementName isEqualToString:@"location"])
				theMeme.location = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([elementName isEqualToString:@"posted_from"])
				theMeme.posted_from = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			if([elementName isEqualToString:@"reply_screen_name"])
				theMeme.reply_screen_name = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([elementName isEqualToString:@"reply_id"])
				theMeme.reply_id = [NSNumber numberWithLongLong:[currentStringValue longLongValue]];
			
			if([elementName isEqualToString:@"qta_replies"])
				theMeme.qta_replies = [NSNumber numberWithLongLong:[currentStringValue longLongValue]];

			// TODO: Still to be managed.
//			<channels>
//			<channel>google</channel>
//			<channel>doodle</channel>
//			<channel>logo</channel>
//			</channels>
//			<preferite_this/>
//			<reshare_this/>
			// avatar
			// video
			
			// Here a meme is ended, should be saved.
			// For perfomance reason, we save at <memes/> below
			if([elementName isEqualToString:@"meme"])
			{
				DLog(@"*** meme ended ***\n%@\n*** **** ***", theMeme);
			}
			// event meme_type
			if([elementName isEqualToString:@"name"])
				theMeme.event_name = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([elementName isEqualToString:@"when"])
			{
				NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:kMeemiDatesFormat];
				theMeme.event_when = [dateFormatter dateFromString:currentStringValue];
				[dateFormatter release];
			}
			if([elementName isEqualToString:@"where"])
				theMeme.event_where = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

			// image meme_type
			if([elementName isEqualToString:@"image"])
				theMeme.image_url = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([elementName isEqualToString:@"image_medium"])
				theMeme.image_medium_url = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			if([elementName isEqualToString:@"image_small"])
				theMeme.image_small_url = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

			// quote meme_type
			if([elementName isEqualToString:@"source"])
				theMeme.quote_source = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			// link meme_type
			if([elementName isEqualToString:@"link"])
				theMeme.link = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		}
		// It's not a newMeme, but with different qta_reply?
		if([elementName isEqualToString:@"qta_replies"])
		{
			theMeme.qta_replies = [NSNumber numberWithLongLong:[currentStringValue longLongValue]];
		}
		// Get the timestamp in any case for checking end
		if([elementName isEqualToString:@"dt_last_movement"])
		{
			if(lastMemeTimestamp != nil)
			{
				[lastMemeTimestamp release];
				lastMemeTimestamp = nil;
			}
			NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:kMeemiDatesFormat];
			lastMemeTimestamp = [dateFormatter dateFromString:currentStringValue];
			[lastMemeTimestamp retain];
			[dateFormatter release];
		}
		
		// should end? If YES, commit the CoreData objects to the db
		if([elementName isEqualToString:@"memes"])
		{
			NSError *error;
			if (![self.managedObjectContext save:&error])
			{
                DLog(@"Failed to save to data store: %@", [error localizedDescription]);
                NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
                if(detailedErrors != nil && [detailedErrors count] > 0) 
					for(NSError* detailedError in detailedErrors) 
						DLog(@"  DetailedError: %@", [detailedError userInfo]);
                else 
					DLog(@"  %@", [error userInfo]);
			}
			// DEBUG: what we read
			ALog(@"Read %d records from page %d\nNew users: %@", howMany, newMemesPageWatermark, newUsersFromNewMemes);
			// return to delegate 1 if we should continue, 0 if we should stop here.
			int retValue;
			if(howManyRequestTotal >= self.memeNumber ||
				[lastMemeTimestamp compare:[NSDate dateWithTimeIntervalSinceNow:self.memeTime * 3600]] == NSOrderedDescending ||
				[self.lastReadDate compare:lastMemeTimestamp] == NSOrderedDescending)
			{
				retValue = 0;
				self.lastReadDate = [NSDate dateWithTimeIntervalSinceNow:-30];
				[[NSUserDefaults standardUserDefaults] setObject:self.lastReadDate forKey:@"lastRead"];
			}
			else
				retValue = 1;
			[self.delegate meemi:MmGetNew didFinishWithResult:retValue];
		}
	}
    if ([elementName isEqualToString:@"name"])
		self.placeName = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([elementName isEqualToString:@"countryName"])
		self.state = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([elementName isEqualToString:@"distance"])
		sscanf([currentStringValue cStringUsingEncoding:NSASCIIStringEncoding], "%lf", &distance);

	if(self.currentRequest == MmGetUser)
	{
		if([elementName isEqualToString:@"avatars"])
			theUser.info = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		else if([elementName isEqualToString:@"meemi"])
			// user info end, save...
			ALog(@"New user saved %@", theUser.screen_name);
		else if([elementName isEqualToString:@"profile"])
			theUser.profile = [currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	}
    // reset currentStringValue for the next cycle
    [currentStringValue release];
    currentStringValue = nil;
}

#pragma mark API

#define kAPIKey @"cf5557e9e1ed41683e1408aefaeeb4c6ee23096b"

-(NSString *)getResponseDescription:(MeemiResult)response
{
	NSString *ret;
	switch (response) 
	{
		case MmUserExists:
			ret = NSLocalizedString(@"User valid", @"");
			break;
		case MmWrongKey:
			ret = NSLocalizedString(@"Key not valid", @"");
			break;
		case MmWrongPwd:
			ret = NSLocalizedString(@"meemi_id or pwd not valid.", @"");
			break;
		case MmUserNotExists:
			ret = NSLocalizedString(@"User do not exists or is not active.", @"");
			break;
		case MmNoRecipientForPrivateMeme:
			ret = [NSString stringWithFormat:NSLocalizedString(@"Error %d", @""), response];
			break;
		case MmNoReplyAllowed:
			ret = [NSString stringWithFormat:NSLocalizedString(@"Error %d", @""), response];
			break;
		case MmPostOK:
			ret = NSLocalizedString(@"Post successful", @"");
			break;
		case MmNotLoggedIn:
			ret = NSLocalizedString(@"User not logged", @"");
			break;
		case MmMarked:
			ret = [NSString stringWithFormat:NSLocalizedString(@"Error %d", @""), response];
			break;
		case MmAddedToFavs:
			ret = [NSString stringWithFormat:NSLocalizedString(@"Error %d", @""), response];
			break;
		case MmDeletedFromFavs:
			ret = [NSString stringWithFormat:NSLocalizedString(@"Error %d", @""), response];
			break;
		case MmChanged:
			ret = [NSString stringWithFormat:NSLocalizedString(@"Error %d", @""), response];
			break;
		case MmNotYours:
			ret = [NSString stringWithFormat:NSLocalizedString(@"Error %d", @""), response];
			break;
		case MmMemeRemoved:
			ret = [NSString stringWithFormat:NSLocalizedString(@"Error %d", @""), response];
			break;
		case MmMemeDoNotExists:
			ret = [NSString stringWithFormat:NSLocalizedString(@"Error %d", @""), response];
			break;
		case MmUndefinedError:
			ret = NSLocalizedString(@"Undefined error.", @"");
			break;
		default:
			ret = [NSString stringWithFormat:NSLocalizedString(@"REALLY undefined error: %d", @""), response];
			break;
	}
	return ret;
}

-(void)startRequestToMeemi:(ASIFormDataRequest *)request
{
	NSAssert(delegate, @"delegate not set in Meemi");
	// build the password using SHA-256
	unsigned char hashedChars[32];
	CC_SHA256([self.password UTF8String],
			  [self.password lengthOfBytesUsingEncoding:NSUTF8StringEncoding], 
			  hashedChars);
	NSString *hashedData = [[NSData dataWithBytes:hashedChars length:32] description];
    hashedData = [hashedData stringByReplacingOccurrencesOfString:@" " withString:@""];
    hashedData = [hashedData stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hashedData = [hashedData stringByReplacingOccurrencesOfString:@">" withString:@""];	
	[request setPostValue:self.screenName forKey:@"meemi_id"];
	[request setPostValue:hashedData forKey:@"pwd"];
	[request setPostValue:kAPIKey forKey:@"app_key"];
	[request setDelegate:self];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	self.busy = YES;
	[request startAsynchronous];			
}

// Validates user and pwd, write them into appdefaults
-(void)validateUser:(NSString *) meemi_id usingPassword:(NSString *)pwd
{
	// Sanity checks
	NSAssert(delegate, @"delegate not set in Meemi");
	// Remember user and pwd in our structures
	self.screenName = meemi_id;
	self.password = pwd;
	// Set current request type
	self.currentRequest = MmRValidateUser;
	
	// API for user testing
	NSURL *url = [NSURL URLWithString:@"http://meemi.com/api/p/exists"];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[self startRequestToMeemi:request];
}

- (void)queueFinished:(ASINetworkQueue *)queue
{
	// You could release the queue here if you wanted
	if ([[self networkQueue] requestsCount] == 0) 
	{
		[self setNetworkQueue:nil]; 
		[self.networkQueue release];
	}
	ALog(@"Queue finished");
	// if we what read were the new users, save modifications and release the array...
	if(self.currentRequest == MmGetUser)
	{
		NSError *error;
		if (![self.managedObjectContext save:&error])
		{
			DLog(@"Failed to save to data store: %@", [error localizedDescription]);
			NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
			if(detailedErrors != nil && [detailedErrors count] > 0) 
				for(NSError* detailedError in detailedErrors) 
					DLog(@"  DetailedError: %@", [detailedError userInfo]);
			else 
				DLog(@"  %@", [error userInfo]);
		}
		[newUsersFromNewMemes release];
		newUsersFromNewMemes = nil;
		self.busy = NO;
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		// OK. Now get avatar images.
		[self updateAvatars];
	}
}

-(void)getAvatarImageIfNeeded:(id)forThisAvatar
{
	NSURL *url;
	Avatar *thisAvatar = forThisAvatar;
	NSString *temp = [[NSString alloc] initWithData:thisAvatar.small encoding:NSUTF8StringEncoding];
	if((url = [NSURL URLWithString:temp]) != nil)
	{
		// get avatar and store it
		DLog(@"getting small avatar for %@ from %@", thisAvatar.user.screen_name, temp);
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			thisAvatar.small = [request responseData];
		}		
		else {
			ALog(@"Error %@ in getting %@", [error localizedDescription], temp);
		}
	}
	[temp release];
	
	temp = [[NSString alloc] initWithData:thisAvatar.medium encoding:NSUTF8StringEncoding];
	if((url = [NSURL URLWithString:temp]) != nil)
	{
		// get avatar and store it
		DLog(@"getting medium avatar for %@ from %@", thisAvatar.user.screen_name, temp);
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			thisAvatar.medium = [request responseData];
		}		
		else {
			ALog(@"Error %@ in getting %@", [error localizedDescription], temp);
		}
	}
	[temp release];
	
//	temp = [[NSString alloc] initWithData:thisAvatar.original encoding:NSUTF8StringEncoding];
//	if((url = [NSURL URLWithString:temp]) != nil)
//	{
//		// get avatar and store it
//		DLog(@"getting original avatar for %@ from %@", thisAvatar.user.screen_name, temp);
//		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
//		[request startSynchronous];
//		NSError *error = [request error];
//		if (!error) {
//			thisAvatar.original = [request responseData];
//		}
//		else {
//			ALog(@"Error %@ in getting %@", [error localizedDescription], temp);
//		}
//	}
//	[temp release];
	if([self.managedObjectContext hasChanges])
	{
		NSError *error;
		if (![self.managedObjectContext save:&error])
		{
			ALog(@"Failed to save to data store: %@", [error localizedDescription]);
			NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
			if(detailedErrors != nil && [detailedErrors count] > 0) 
				for(NSError* detailedError in detailedErrors) 
					ALog(@"  DetailedError: %@", [detailedError userInfo]);
			else 
				ALog(@"  %@", [error userInfo]);
		}	
		ALog(@"saved %@", thisAvatar.user.screen_name);
	}
	else {
		ALog(@"No needs to save %@", thisAvatar.user.screen_name);
	}
}

-(void)getBackToDelegateAfterUpdateAvatars:(id)theDelegate
{
	ALog(@"in getBackToDelegateAfterUpdateAvatars:");
	self.busy = NO;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[(id<MeemiDelegate>)theDelegate meemi:MmGetNewUsers didFinishWithResult:0];
}

-(void)updateAvatars
{
	[theQueue setMaxConcurrentOperationCount:1];
	DLog(@"Loading NSOperationQueue in updateAvatars");
	self.busy = YES;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Avatar" inManagedObjectContext:self.managedObjectContext];
	[request setEntity:entity];
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	for(Avatar *newAvatar in fetchResults)
	{
		NSInvocationOperation *theOp = [[[NSInvocationOperation alloc] initWithTarget:self 
																			 selector:@selector(getAvatarImageIfNeeded:) 
																			   object:newAvatar] autorelease];
		[theQueue addOperation:theOp];
	}
	[request release];
	// The last operation get back to the delegate...
	NSInvocationOperation *theOp = [[[NSInvocationOperation alloc] initWithTarget:self 
																		 selector:@selector(getBackToDelegateAfterUpdateAvatars:) 
																		   object:self.delegate] autorelease];
	[theQueue addOperation:theOp];
	
}

-(void)getNewUsers
{
	NSAssert(self.isValid, @"getNewMemes: called without valid session");

	// Stop anything already in the queue before removing it
	if(self.networkQueue != nil)
	{
		[[self networkQueue] cancelAllOperations];
		[self.networkQueue release];
		self.networkQueue = nil;
	}
	// if nothing to do... go directly to updateAvatars.
	if([newUsersFromNewMemes count] == 0)
	{
		[newUsersFromNewMemes release];
		newUsersFromNewMemes = nil;
		// OK. Now get avatar images.
		[self updateAvatars];
	}		
	else
	{
		self.busy = YES;
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		// Creating a new queue each time we use it means we don't have to worry about clearing delegates or resetting progress tracking
		[self setNetworkQueue:[ASINetworkQueue queue]];
		[[self networkQueue] setDelegate:self];
		[[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
		[self networkQueue].maxConcurrentOperationCount = 1;
		
		for(NSString *newUser in newUsersFromNewMemes)
		{
			self.currentRequest = MmGetUser;
			NSURL *url = [NSURL URLWithString:
						  [NSString stringWithFormat:@"http://meemi.com/api/%@/profile", newUser]];
			
			ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
			// build the password using SHA-256
			unsigned char hashedChars[32];
			CC_SHA256([self.password UTF8String],
					  [self.password lengthOfBytesUsingEncoding:NSUTF8StringEncoding], 
					  hashedChars);
			NSString *hashedData = [[NSData dataWithBytes:hashedChars length:32] description];
			hashedData = [hashedData stringByReplacingOccurrencesOfString:@" " withString:@""];
			hashedData = [hashedData stringByReplacingOccurrencesOfString:@"<" withString:@""];
			hashedData = [hashedData stringByReplacingOccurrencesOfString:@">" withString:@""];	
			[request setPostValue:self.screenName forKey:@"meemi_id"];
			[request setPostValue:hashedData forKey:@"pwd"];
			[request setPostValue:kAPIKey forKey:@"app_key"];
			[request setDelegate:self];
			[[self networkQueue] addOperation:request];
			ALog(@"Adding %@ to queue", newUser);
		}
		[[self networkQueue] go];
	}
}

-(void)getNewMemes:(BOOL)fromScratch
{
	NSAssert(self.isValid, @"getNewMemes: called without valid session");
	self.currentRequest = MmGetNew;
	
	// Now setup the URI depending on the request
	NSURL *url;
	if(fromScratch)
	{
		url = [NSURL URLWithString:
			   [NSString stringWithFormat:@"http://meemi.com/api3/%@/wf/limit_10", self.screenName]];
		newUsersFromNewMemes = [[NSMutableArray alloc] initWithCapacity:10];
		newMemesPageWatermark = 1;
		howManyRequestTotal = 0;
	}
	else 
	{
		newMemesPageWatermark++;
		url = [NSURL URLWithString:
			   [NSString stringWithFormat:@"http://meemi.com/api3/%@/wf/limit_10/page_%d", 
				self.screenName, newMemesPageWatermark]];
	}
	
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[self startRequestToMeemi:request];
}

-(void)markNewMemesRead
{
	NSAssert(self.isValid, @"markNewMemesRead: called without valid session");
	self.currentRequest = MmMarkNewRead;
	NSURL *url = [NSURL URLWithString:
				  [NSString stringWithFormat:@"http://meemi.com/api/%@/wf/mark/only_new_memes", self.screenName]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[self startRequestToMeemi:request];
}

-(void)postSomething:(NSString *)withDescription withLocalization:(BOOL)canBeLocalized andOptionalArg:(id)whatever 
			replyWho:(NSString *)replyScreenName replyNo:(NSNumber *)replyID
{
	// accomodate different URLs for save and reply actions
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://meemi.com/api/%@/%@", self.screenName,
									   (replyScreenName == nil) ? @"save" : @"reply"]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	if(self.currentRequest == MmRPostImage)
	{
		[request setPostValue:@"image" forKey:@"meme_type"];
		[request setPostValue:@"PC" forKey:@"flag"];
		NSData *imageAsJPEG = UIImageJPEGRepresentation((UIImage *)whatever, 0.75);
		[request setData:imageAsJPEG withFileName:@"unuseful.jpg" andContentType:@"image/jpeg" forKey:@"img_pc"];
	}
	else // this is MmRPostText
	{
		[request setPostValue:@"text" forKey:@"meme_type"];
		[request setPostValue:(NSString *)whatever forKey:@"channels"];
	}
	// If this is a reply
	if(replyScreenName != nil)
	{
		[request setPostValue:replyScreenName forKey:@"reply_screen_name"];
		NSString *temp = [NSString stringWithFormat:@"%@", replyID];
		[request setPostValue:temp forKey:@"reply_meme_id"];
	}
	if(!canBeLocalized)
		[request setPostValue:@"An unknown place, with an iPhone App still to be announced" forKey:@"location"];
	else
		[request setPostValue:self.nearbyPlaceName forKey:@"location"];
	[request setPostValue:withDescription forKey:@"text_content"];
	[self startRequestToMeemi:request];
}

-(void)postImageAsMeme:(UIImage *)image withDescription:(NSString *)description withLocalization:(BOOL)canBeLocalized
{
	// Sanity checks
	NSAssert(self.isValid, @"postImageAsMeme:withDescription called without valid session");
	// Set current request type
	self.currentRequest = MmRPostImage;
	[self postSomething:description withLocalization:canBeLocalized andOptionalArg:image replyWho:nil replyNo:nil];
}

-(void)postImageAsReply:(UIImage *)image withDescription:(NSString *)description withLocalization:(BOOL)canBeLocalized 
			   replyWho:(NSString *)replyScreenName replyNo:(NSNumber *)replyID;
{
	// Sanity checks
	NSAssert(self.isValid, @"postImageAsReply:withDescription called without valid session");
	// Set current request type
	self.currentRequest = MmRPostImage;
	[self postSomething:description withLocalization:canBeLocalized andOptionalArg:image replyWho:replyScreenName replyNo:replyID];
}

-(void)postTextAsMeme:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized
{
	// Sanity checks
	NSAssert(self.isValid, @"postTextAsMeme:withDescription called without valid session");
	// Set current request type
	self.currentRequest = MmRPostText;
	[self postSomething:description withLocalization:canBeLocalized andOptionalArg:channel replyWho:nil replyNo:nil];
}

-(void)postTextReply:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized 
			replyWho:(NSString *)replyScreenName replyNo:(NSNumber *)replyID
{
	// Sanity checks
	NSAssert(self.isValid, @"postTextAsReply:withDescription called without valid session");
	// Set current request type
	self.currentRequest = MmRPostText;
	[self postSomething:description withLocalization:canBeLocalized andOptionalArg:channel replyWho:replyScreenName replyNo:replyID];
}

#pragma mark CLLocationManagerDelegate and its delegate

- (void)stopLocation
{
	if(locationManager)
		[locationManager stopUpdatingLocation];
}

- (void)startLocation
{
	// If user already deny once this session, bail out
	if(self.isLCDenied)
		return;
	// if user denied thrice, bail out...
	if(self.nLocationUseDenies >= 3)
		return;
    // Create the location manager if this object does not
    // already have one.
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];
	
	locationManager.delegate = self;
	locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
	
	// Set a movement threshold for new events
	locationManager.distanceFilter = 100;
	
	// We want a full service :)
	needLocation = needG13N = YES;
	
	[locationManager startUpdatingLocation];	
}


// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    // If it's a relatively recent event, turn off updates to save power
    NSDate* eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 5.0)
    {
		// Check accuracy and continue to look if more than 100m...
		if(newLocation.horizontalAccuracy < 100)
			[manager stopUpdatingLocation];
		
		// Pass location to Flurry
		[FlurryAPI setLocation:newLocation];
		needLocation = NO;
		// init a safe value, if void and if we don't have a reverse location
		if([self.nearbyPlaceName isEqualToString:@""])
		{
			self.nearbyPlaceName = [NSString stringWithFormat:@"lat %+.4f, lon %+.4f ±%.0fm",
									newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy];
			ALog(@"Got a position: lat %+.4f, lon %+.4f ±%.0fm\nPlacename still unknown.",
				 newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy);
		}
			// Set the new position, in case we already have a reverse geolocation, but we have a new position
		if(self.placeName != nil && self.state != nil)
		{
			self.nearbyPlaceName = [NSString stringWithFormat:@"%@, %@ (lat %+.4f, lon %+.4f ±%.0fm)",
									[self.placeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
									[self.state stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
									locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude, 
									locationManager.location.horizontalAccuracy];
			ALog(@"Got a new position (reverse geoloc already in place): %@", self.nearbyPlaceName);
		}
			
		// Notify the world that we have found ourselves
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kGotLocation object:self]];
		// Do we need reverse geolocation?
		if(needG13N)
		{
			// protect ourselves from parallel connections... if this pointer is not nil another connection is running
			if(theReverseGeoConnection != nil)
				return;
			
			NSString *urlString = [NSString stringWithFormat:@"http://ws.geonames.org/findNearbyPlaceName?lat=%+.6f&lng=%+.6f",
								   newLocation.coordinate.latitude, newLocation.coordinate.longitude];
			ALog(@"Starting reverse geolocation via <%@>", urlString);
			NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString] 
														cachePolicy:NSURLRequestReturnCacheDataElseLoad
													timeoutInterval:30];
			xmlData = nil;
			theReverseGeoConnection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
		}
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	// if the user don't want to give us the rights, give up.
	if(error.code == kCLErrorDenied)
	{
		[manager stopUpdatingLocation];
		// mark that user already denied us for this session
		self.lcDenied = YES;
		// add one to Get how many times user refused and save to default
		self.nLocationUseDenies = self.nLocationUseDenies + 1;
		// if denied thrice... signal it!
//		if(self.nLocationUseDenies >= 3)
//			[[Beacon shared] startSubBeaconWithName:@"userRefusedLocation" timeSession:NO];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setInteger:self.nLocationUseDenies forKey:@"userDeny"];
	}
}

#pragma mark NSURLConnection delegates

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(xmlData == nil)
	{
		xmlData = [NSMutableData dataWithCapacity:10];
		[xmlData retain];
	}
	[xmlData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
//	NSString* aStr = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
//	DLog(@"Answer received from geolocation service: %@", aStr);
//	[aStr release];
    if (addressParser) // addressParser is an NSXMLParser instance variable
        [addressParser release];
	addressParser = [[NSXMLParser alloc] initWithData:xmlData];
	[addressParser setDelegate:self];
    [addressParser setShouldResolveExternalEntities:YES];
    if([addressParser parse])
	{
		// Also trims strings
		self.nearbyPlaceName = [NSString stringWithFormat:@"%@, %@ (lat %+.4f, lon %+.4f ±%.0fm)",
								[self.placeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
								[self.state stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
								locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude, 
								locationManager.location.horizontalAccuracy];
		ALog(@"Got a full localization: %@", self.nearbyPlaceName);
		needG13N = NO;
		// Notify the world that we have found ourselves
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kGotLocation object:self]];
	}
	[xmlData release];
	theReverseGeoConnection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	DLog(@"connection didFailWithError");
	if(xmlData != nil)
		[xmlData release];
}


@end
