//
//  Meemi.m
//  Meemi
//
//  Created by Giacomo Tufano on 18/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "Meemi.h"

#import "ASIFormDataRequest.h"

// for SHA-256
#include <CommonCrypto/CommonDigest.h>

static Meemi *sharedSession = nil;

@implementation Meemi

@synthesize valid, screenName, password, delegate, currentRequest;

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
		return self;
	}
	else
		return nil;
}

-(id)initWithDelegate:(id<MeemiDelegate>)d
{
	if(self = [super init])
	{
		self.valid = NO;
		self.delegate = d;
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
	NSLog(@"request sent and answer received. Calling parser for processing\n");
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

// Parse response string
// returns YES if xml parsing succeeds, NO otherwise
- (BOOL) parse:(NSData *)responseData
{
	NSLog(@"Startig parse of: %@", responseData);
	NSString *temp = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"As string: \"%@\"", temp);
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

#pragma mark NSXMLParser delegate

// NSXMLParser delegates

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	// DEBUG: parse attributes
	NSLog(@"Element Start: <%@>", elementName);
	NSEnumerator *enumerator = [attributeDict keyEnumerator];
	id key;
	while ((key = [enumerator nextObject])) 
	{
		NSLog(@"attribute \"%@\" is \"%@\"", key, [attributeDict objectForKey:key]);
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
			if([code intValue] == 0)
				[self markSessionValid];
			else // mark session not valid
				self.valid = NO;
			[self.delegate meemi:self.currentRequest didFinishWithResult:[code intValue]];
		}
		// If it was animage post, check return and inform delegate
		if(self.currentRequest == MmRPostImage)
		{
			NSString *code = [attributeDict objectForKey:@"code"];
			// Defensive code for the case "code" do not exists
			NSAssert(code, @"In NSXMLParser: attribute code for <message> is missing");
			// if return code is OK, get back to delegate
			if([code intValue] == 7)
				[self.delegate meemi:self.currentRequest didFinishWithResult:[code intValue]];
		}
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	NSLog(@"Data: %@", string);
    if (!currentStringValue)
        // currentStringValue is an NSMutableString instance variable
        currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
    [currentStringValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	NSLog(@"Element End: %@", elementName);
	NSLog(@"<%@> fully received with value: <%@>", elementName, currentStringValue);
	
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
	// build the password using SHA-256
	unsigned char hashedChars[32];
	CC_SHA256([pwd UTF8String],
			  [pwd lengthOfBytesUsingEncoding:NSUTF8StringEncoding], 
			  hashedChars);
	NSString *hashedData = [[NSData dataWithBytes:hashedChars length:32] description];
    hashedData = [hashedData stringByReplacingOccurrencesOfString:@" " withString:@""];
    hashedData = [hashedData stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hashedData = [hashedData stringByReplacingOccurrencesOfString:@">" withString:@""];	
	
	// API for user testing
	NSURL *url = [NSURL URLWithString:@"http://meemi.com/api/p/exists"];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:meemi_id forKey:@"meemi_id"];
	[request setPostValue:hashedData forKey:@"pwd"];
	[request setPostValue:kAPIKey forKey:@"app_key"];
	[request setDelegate:self];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[request startAsynchronous];
}

-(void)postImageAsMeme:(UIImage *)image withDescription:(NSString *)description
{
	// Sanity checks
	NSAssert(delegate, @"delegate not set in Meemi");
	NSAssert(self.isValid, @"postImageAsMeme:withDescription called without valid session");
	// Set current request type
	self.currentRequest = MmRPostImage;
	// build the password using SHA-256
	unsigned char hashedChars[32];
	CC_SHA256([self.password UTF8String],
			  [self.password lengthOfBytesUsingEncoding:NSUTF8StringEncoding], 
			  hashedChars);
	NSString *hashedData = [[NSData dataWithBytes:hashedChars length:32] description];
    hashedData = [hashedData stringByReplacingOccurrencesOfString:@" " withString:@""];
    hashedData = [hashedData stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hashedData = [hashedData stringByReplacingOccurrencesOfString:@">" withString:@""];	
	
	// API for user testing
	NSURL *url = [NSURL URLWithString:
				  [NSString stringWithFormat:@"http://meemi.com/api/%@/save", self.screenName]];
	ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
	[request setPostValue:self.screenName forKey:@"meemi_id"];
	[request setPostValue:hashedData forKey:@"pwd"];
	[request setPostValue:kAPIKey forKey:@"app_key"];
	[request setPostValue:@"image" forKey:@"meme_type"];
	[request setPostValue:@"an iPhone App to be announced" forKey:@"location"];
	[request setPostValue:description forKey:@"image_description"];
	[request setData:UIImageJPEGRepresentation(image, 0.75) forKey:@"image_pc"];
	[request setDelegate:self];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[request startAsynchronous];	
}

@end
