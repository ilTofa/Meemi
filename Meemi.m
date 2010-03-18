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

static Meemi *sharedMeemi = nil;

@implementation Meemi

@synthesize valid, screenName, password;

#pragma mark Singleton Class Setup

+(Meemi *)sharedInstance
{
	@synchronized(self) {
        if (sharedMeemi == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return sharedMeemi;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedMeemi == nil) {
            sharedMeemi = [super allocWithZone:zone];
            return sharedMeemi;  // assignment and return on first allocation
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

#pragma mark ASIHTTPRequest delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
	NSString *responseString = [request responseString];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSLog(@"request sent and answer received\n");
	
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	NSError *error = [request error];
	NSLog(@"Error: %@", error);
	UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
														message:[error localizedDescription]
													   delegate:nil
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil] autorelease];
	[theAlert show];
}


#pragma mark API

#define kAPIKey @"cf5557e9e1ed41683e1408aefaeeb4c6ee23096b"

// Validates user and pwd, write them into appdefaults
-(BOOL)validateUser:(NSString *) meemi_id usingPassword:(NSString *)pwd
{
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
	ASIFormDataRequest *request = [ASIHTTPRequest requestWithURL:url];
	[request setPostValue:meemi_id forKey:@"meemi_id"];
	[request setPostValue:hashedData forKey:@"pwd"];
	[request setPostValue:kAPIKey forKey:@"app_key"];
	[request setDelegate:self];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	[request startAsynchronous];

	// user is OK. Save it.
	self.screenName = meemi_id;
	self.password = pwd;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:meemi_id forKey:@"screenName"];
	[defaults setObject:pwd forKey:@"password"];	
	return YES;
}

@end
