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

// for SHA-256
#include <CommonCrypto/CommonDigest.h>

static Meemi *sharedSession = nil;

@implementation Meemi

@synthesize valid, screenName, password, delegate, currentRequest;
@synthesize lcDenied, nLocationUseDenies, nearbyPlaceName, placeName, state;
@synthesize managedObjectContext;
@synthesize networkQueue;

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
		// get number of times user denied location use..
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		self.nLocationUseDenies = [defaults integerForKey:@"userDeny"];
		// At the moment, user have not denied anything
		self.lcDenied = NO;
		// init the Queue
		theQueue = [[NSOperationQueue alloc] init];
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
	DLog(@"request sent and answer received. Calling parser for processing\n");
	[self parse:responseData];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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
	self.valid = YES;
}

// Parse response string
// returns YES if xml parsing succeeds, NO otherwise
- (BOOL) parse:(NSData *)responseData
{
	DLog(@"Starting parse of: %@", responseData);
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
		// Get number of memes
		// not useful in itself, COULD be used to understand when the last fetch has been done (quantity < 20)
		if([elementName isEqualToString:@"memes"])
		{
			NSString *memeQuantity = [attributeDict objectForKey:@"qta"];
			NSAssert(memeQuantity, @"In NSXMLParser: attribute qta for <memes> is missing");
			DLog(@"*** Got %d memes in reply to new_meme_request", [memeQuantity intValue]);
			howMany = [memeQuantity intValue];
		}
		// if a meme is coming...
		if([elementName isEqualToString:@"meme"])
		{
			DLog(@"*** got a new meme");
			theMeme = (Meme *)[NSEntityDescription insertNewObjectForEntityForName:@"Meme" inManagedObjectContext:self.managedObjectContext];
			theMeme.id = [NSNumber numberWithLongLong:[[attributeDict objectForKey:@"id"] longLongValue]];
			theMeme.screen_name = [attributeDict objectForKey:@"screen_name"];
			// Now that theMeme is started, set the relationships with theUser (and create it if not existing)
			[self setupMemeRelationshipsFrom:theMeme.screen_name];
			theMeme.qta_replies = [NSNumber numberWithInt:[[attributeDict objectForKey:@"qta_replies"] intValue]];
			theMeme.type = [attributeDict objectForKey:@"type"];
			// TODO: avoid work around not implemented type different from text
			if(![theMeme.type isEqualToString:@"text"])
				theMeme.content = [NSString stringWithFormat:@"This meme is a %@", theMeme.type];
			theMeme.favourite = [NSNumber numberWithInt:[[attributeDict objectForKey:@"favourite"] intValue]];
			// Workaround stupid date
			NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];
			NSString *tempDate = [NSString stringWithFormat:@"%@ +0200", [attributeDict objectForKey:@"date_time"]];
			theMeme.date_time = [dateFormatter dateFromString:tempDate];
			[dateFormatter release];
		}
		// Other parts of a meme
		if([elementName isEqualToString:@"avatars"])
		{
			// TODO: strip -s from base URL...
			theAvatar.baseURL = [attributeDict objectForKey:@"small"];
//			theMeme.avatar_small = [attributeDict objectForKey:@"small"];
//			DLog(@"size before: %d, size after: %d", [[attributeDict objectForKey:@"small"] length], [theMeme.avatar_small length]);
//			DLog(@"theMeme.avatar_small = \"%@\"", theMeme.avatar_small);
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
				theUser.birth = [dateFormatter dateFromString:[attributeDict objectForKey:@"since"]];
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
			// return to delegate how many records we read and, therefore, if there are still records to fetch...
			// If records are 20, return the page number as addition to 20...
			int retValue = (howMany == 20) ? 20 + newMemesPageWatermark : howMany;
			[self.delegate meemi:MmGetNew didFinishWithResult:retValue];
		}	
		// Here a meme is ended, should be saved. :)
		if([elementName isEqualToString:@"meme"])
		{
			DLog(@"*** meme ended ***\n%@\n*** **** ***", theMeme);
		}
		// Other things
		if([elementName isEqualToString:@"original_link"])
			theMeme.original_link = currentStringValue;
		if([elementName isEqualToString:@"location"])
			theMeme.location = currentStringValue;
		if([elementName isEqualToString:@"source"])
			theMeme.source = currentStringValue;
		if([elementName isEqualToString:@"chans"])
			theMeme.chans = currentStringValue;
		if([elementName isEqualToString:@"content"])
			theMeme.content = currentStringValue;
	}
    if ([elementName isEqualToString:@"name"])
		self.placeName = currentStringValue;
	
	if ([elementName isEqualToString:@"countryName"])
		self.state = currentStringValue;
	
	if ([elementName isEqualToString:@"distance"])
		sscanf([currentStringValue cStringUsingEncoding:NSASCIIStringEncoding], "%lf", &distance);

	if(self.currentRequest == MmGetUser)
	{
		if([elementName isEqualToString:@"avatars"])
			theUser.info = currentStringValue;
		else if([elementName isEqualToString:@"meemi"])
			// user info end, save...
			ALog(@"New user saved %@", theUser.screen_name);
		else if([elementName isEqualToString:@"profile"])
			theUser.profile = currentStringValue;		
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
		// OK. Now get avatar images.
		[self updateAvatars];
	}
}

-(void)getAvatarImageIfNeeded:(id)forThisAvatar
{
	BOOL needSave = NO;
	NSURL *url;
	Avatar *thisAvatar = forThisAvatar;
	NSString *temp = [[NSString alloc] initWithData:thisAvatar.small encoding:NSUTF8StringEncoding];
	if((url = [NSURL URLWithString:temp]) != nil)
	{
		// get avatar and store it
		ALog(@"getting small avatar for %@ from %@", thisAvatar.user.screen_name, temp);
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			theAvatar.small = [request responseData];
			needSave = YES;
		}		
	}
	[temp release];
	
	temp = [[NSString alloc] initWithData:thisAvatar.medium encoding:NSUTF8StringEncoding];
	if((url = [NSURL URLWithString:temp]) != nil)
	{
		// get avatar and store it
		ALog(@"getting medium avatar for %@ from %@", thisAvatar.user.screen_name, temp);
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			theAvatar.medium = [request responseData];
			needSave = YES;
		}		
	}
	[temp release];
	
	temp = [[NSString alloc] initWithData:thisAvatar.original encoding:NSUTF8StringEncoding];
	if((url = [NSURL URLWithString:temp]) != nil)
	{
		// get avatar and store it
		ALog(@"getting original avatar for %@ from %@", thisAvatar.user.screen_name, temp);
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
		[request startSynchronous];
		NSError *error = [request error];
		if (!error) {
			theAvatar.original = [request responseData];
			needSave = YES;
		}		
	}
	[temp release];
	if(needSave)
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
	}
}

-(void)updateAvatars
{
	[theQueue setMaxConcurrentOperationCount:1];
	DLog(@"Loading NSOperationQueue in updateAvatars");
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	// We're looking for an User with this screen_name.
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
	// Creating a new queue each time we use it means we don't have to worry about clearing delegates or resetting progress tracking
	[self setNetworkQueue:[ASINetworkQueue queue]];
	[[self networkQueue] setDelegate:self];
//	[[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
//	[[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
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

-(void)getNewMemes:(BOOL)fromScratch
{
	NSAssert(self.isValid, @"getNewMemes: called without valid session");
	self.currentRequest = MmGetNew;
	
	// Now setup the URI depending on the request
	NSURL *url;
	if(fromScratch)
	{
		url = [NSURL URLWithString:
			   [NSString stringWithFormat:@"http://meemi.com/api/%@/wf/only_new_memes", self.screenName]];
		newUsersFromNewMemes = [[NSMutableArray alloc] initWithCapacity:10];
		newMemesPageWatermark = 1;
	}
	else 
	{
		newMemesPageWatermark++;
		url = [NSURL URLWithString:
			   [NSString stringWithFormat:@"http://meemi.com/api/%@/wf/only_new_memes/page_%d", 
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
{
	NSURL *url = [NSURL URLWithString:
				  [NSString stringWithFormat:@"http://meemi.com/api/%@/save", self.screenName]];
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
	[self postSomething:description withLocalization:canBeLocalized andOptionalArg:image];
}

-(void)postTextAsMeme:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized
{
	// Sanity checks
	NSAssert(self.isValid, @"postTextAsMeme:withDescription called without valid session");
	// Set current request type
	self.currentRequest = MmRPostText;
	[self postSomething:description withLocalization:canBeLocalized andOptionalArg:channel];
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
        [manager stopUpdatingLocation];
		
		// Pass location to Flurry
//		[FlurryAPI setLocation:newLocation];
		needLocation = NO;
		DLog(@"Got a position: lat %+.4f, lon %+.4f ±%.0fm\nPlacename still \"%@\"",
							  newLocation.coordinate.latitude, newLocation.coordinate.longitude, 
							  newLocation.horizontalAccuracy, self.nearbyPlaceName);
		// init a safe value, just in case...
		if([self.nearbyPlaceName isEqualToString:@""])
			self.nearbyPlaceName = [NSString stringWithFormat:@"lat %+.4f, lon %+.4f ±%.0fm",
									locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude, 
									locationManager.location.horizontalAccuracy, self.nearbyPlaceName];
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
			DLog(@"Starting reverse geolocation via <%@>", urlString);
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
								[placeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
								[state stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]],
								locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude, 
								locationManager.location.horizontalAccuracy, self.nearbyPlaceName];
		DLog(@"Got a full localization: %@", self.nearbyPlaceName);
		needG13N = NO;
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
