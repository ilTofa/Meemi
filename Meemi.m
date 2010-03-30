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
@synthesize lcDenied, nLocationUseDenies, nearbyPlaceName, placeName, state;
@synthesize managedObjectContext;

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

    if ([elementName isEqualToString:@"name"])
		self.placeName = currentStringValue;
	
	if ([elementName isEqualToString:@"countryName"])
		self.state = currentStringValue;
	
	if ([elementName isEqualToString:@"distance"])
		sscanf([currentStringValue cStringUsingEncoding:NSASCIIStringEncoding], "%lf", &distance);
	
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
	// DEBUG
	NSLog(@"Auth: <meemi_id=%@&pwd=%@&app_key=%@>", meemi_id, hashedData, kAPIKey);
	[request setDelegate:self];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[request startAsynchronous];
}

-(void)postSomething:(NSString *)withDescription withLocalization:(BOOL)canBeLocalized andOptionalArg:(id)whatever
{
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
	[request setDelegate:self];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	[request startAsynchronous];	
}

-(void)postImageAsMeme:(UIImage *)image withDescription:(NSString *)description withLocalization:(BOOL)canBeLocalized
{
	// Sanity checks
	NSAssert(delegate, @"delegate not set in Meemi");
	NSAssert(self.isValid, @"postImageAsMeme:withDescription called without valid session");
	// Set current request type
	self.currentRequest = MmRPostImage;
	[self postSomething:description withLocalization:canBeLocalized andOptionalArg:image];
}

-(void)postTextAsMeme:(NSString *)description withChannel:(NSString *)channel withLocalization:(BOOL)canBeLocalized
{
	// Sanity checks
	NSAssert(delegate, @"delegate not set in Meemi");
	NSAssert(self.isValid, @"postImageAsMeme:withDescription called without valid session");
	// Set current request type
	self.currentRequest = MmRPostText;
	[self postSomething:description withLocalization:canBeLocalized andOptionalArg:channel];
}

#pragma mark CLLocationManagerDelegate and its delegate

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
		locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
		
		// Set a movement threshold for new events
		locationManager.distanceFilter = 200;
		
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
		NSLog(@"Got a position: lat %+.4f, lon %+.4f ±%.0fm\nPlacename still \"%@\"",
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
			NSLog(@"Starting reverse geolocation via <%@>", urlString);
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
//	NSLog(@"Answer received from geolocation service: %@", aStr);
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
		NSLog(@"Got a full localization: %@", self.nearbyPlaceName);
		needG13N = NO;
	}
	[xmlData release];
	theReverseGeoConnection = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"connection didFailWithError");
	if(xmlData != nil)
		[xmlData release];
}


@end
