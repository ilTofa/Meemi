//
//  UserProfile.m
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "UserProfile.h"
#import "MemeOnWeb.h"

#import <QuartzCore/QuartzCore.h>

@implementation UserProfile

@synthesize theAvatar, screenName, realName, birth, location, info, theSegment, followButton, messageButton;
@synthesize theUser;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

-(void)doneWithTextSender
{
	self.navigationController.navigationBarHidden = NO;
	[self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)loadAvatar:(id)sender
{
	MemeOnWeb *controller = [[MemeOnWeb alloc] initWithNibName:@"MemeOnWeb" bundle:nil];
	controller.urlToBeLoaded = theUser.avatar_url;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
	controller = nil;	
}

-(IBAction)sendPrivateMeme:(id)sender
{
	DLog(@"Send a private meme to: %@", self.screenName.text);
	TextSender *controller = [[TextSender alloc] initWithNibName:@"TextSender" bundle:nil];
	controller.delegate = self;
	controller.recipientNames = self.screenName.text;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

-(IBAction)infoSwapped
{
	NSDateFormatter *dateFormatter;
	NSString *birthday;
	switch (self.theSegment.selectedSegmentIndex) 
	{
		case 0:
			info.text = theUser.info;
			info.textAlignment = UITextAlignmentLeft;
			followButton.hidden = messageButton.hidden = YES;
			break;
		case 1:
			info.text = theUser.profile;
			info.textAlignment = UITextAlignmentLeft;
			followButton.hidden = messageButton.hidden = YES;
			break;
		default:
			// dates...
			if(theUser.birth)
			{
				dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setLocale:[NSLocale currentLocale]];
				[dateFormatter setDateStyle:NSDateFormatterLongStyle];
				[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
				birthday = [dateFormatter stringFromDate:theUser.birth];
				[dateFormatter release];			
			}
			else
				birthday = @"";
            if(![[Meemi screenName] isEqualToString:theUser.screen_name])
            {
                info.text = [NSString stringWithFormat:NSLocalizedString(@"\nBorn %@\n\nFollows: %d\nFollowed: %d\n\n%@\n%@", @""),
                             birthday,
                             [theUser.qta_followings intValue], [theUser.qta_followers intValue],
                             [theUser.follow_you boolValue] ? NSLocalizedString(@"He/She follows you", @"") : NSLocalizedString(@"He/she don't follow you", @""),
                             [theUser.you_follow boolValue] ? NSLocalizedString(@"You follow him/her", @"") : NSLocalizedString(@"You don't follow him/her", @"")];
                info.textAlignment = UITextAlignmentCenter;
                self.followButton.hidden = NO;
                [followButton setTitle:[theUser.you_follow boolValue] ? NSLocalizedString(@"Unfollow", @"") : NSLocalizedString(@"Follow", @"") forState:UIControlStateNormal];
                self.messageButton.hidden = NO;
                [messageButton setTitle:NSLocalizedString(@"Send a Meme", @"") forState:UIControlStateNormal];
            }
            else
            {
                info.text = [NSString stringWithFormat:NSLocalizedString(@"\nBorn %@\n\nFollows: %d\nFollowed: %d\n\n%@\n%@", @""),
                             birthday,
                             [theUser.qta_followings intValue], [theUser.qta_followers intValue],
                             @"", @""];
                info.textAlignment = UITextAlignmentCenter;
                self.followButton.hidden = self.messageButton.hidden = YES;
            }
			break;
	}
}

-(void)loadTextInView
{
	// Text
	screenName.text = theUser.screen_name;
    if([[Meemi screenName] isEqualToString:theUser.screen_name])
        realName.text = NSLocalizedString(@"That's you!", @"");
    else
        realName.text = theUser.real_name;
	location.text = theUser.current_location;
	info.text = theUser.info;
	// Image
	UIImage *tempImage = [[UIImage alloc] initWithCGImage:[[UIImage imageWithData:theUser.avatar] CGImage]
													scale:[[UIScreen mainScreen] scale]
											  orientation:UIImageOrientationUp];
	[theAvatar setBackgroundImage:tempImage forState:UIControlStateNormal];
	[tempImage release];
//	[theAvatar setBackgroundImage:[UIImage imageWithData:theUser.avatar] forState:UIControlStateNormal];
	[self infoSwapped];
}

-(void)loadUser:(NSNotification *)note
{
	DLog(@"Now loading user info");
	[ourPersonalMeemi getUser:theUser.screen_name];
}

-(IBAction)followUnfollow:(id)sender
{
	DLog(@"Now %@ user", [theUser.you_follow boolValue] ? @"unfollowing" : @"following");
	if([theUser.you_follow boolValue])
		[ourPersonalMeemi unfollowUser:theUser.screen_name];	
	else
		[ourPersonalMeemi followUser:theUser.screen_name];	
}

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error
{
	UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
														message:NSLocalizedString(@"Error loading data, please try again later", @"")
													   delegate:nil
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil] 
							 autorelease];
	[theAlert show];
}	

-(void)meemi:(MeemiRequest)request didFinishWithResult:(MeemiResult)result
{
	DLog(@"didFinishWithResult in UserProfile. Request is: %d. Result is %d. New infos are: %@", request, result, self.theUser);
	if(result == MmFollowOK)
	{
		DLog(@"didFinishWithResult in UserProfile: MmFollowOK");
		theUser.you_follow = [NSNumber numberWithBool:YES];
		[self infoSwapped];
	}
	if(result == MmUnfollowOK)
	{
		DLog(@"didFinishWithResult in UserProfile: MmUnfollowOK");
		theUser.you_follow = [NSNumber numberWithBool:NO];
		[self infoSwapped];
	}
	if(request == MMGetNewUser)
	{ //update and reload avatar, just in case...
		DLog(@"didFinishWithResult in UserProfile: MMGetNewUser");
		[self performSelectorOnMainThread:@selector(loadTextInView) withObject:nil waitUntilDone:YES];
		[ourPersonalMeemi loadAvatar:theUser.screen_name];
	}
	// It could be MmGetNewUsers (then load the text, and do it on the main thread!).
	if(request == MmGetNewUsers)
	{
		DLog(@"didFinishWithResult in UserProfile: MmGetNewUsers");
		[self performSelectorOnMainThread:@selector(loadTextInView) withObject:nil waitUntilDone:NO];
	}
	// else do nothing... :)
}

-(void)setWatermark:(int)watermark
{ }

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	[self loadTextInView];
	// Setup the Meemi "agent"
	ourPersonalMeemi = [[Meemi alloc] initFromUserDefault];
	if(!ourPersonalMeemi)
		ALog(@"Meemi session init failed. Shit...");
	ourPersonalMeemi.delegate = self;	
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	// Setup toolbar
	UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	NSArray *tempStrings = [NSArray arrayWithObjects:@"Info", @"Profile", @"Extra", nil];
	self.theSegment = [[UISegmentedControl alloc] initWithItems:tempStrings];
	self.theSegment.segmentedControlStyle = UISegmentedControlStyleBar;
    theSegment.tintColor = [UIColor colorWithRed:0.70313 green:0.73477 blue:0.75938 alpha:1.0];
	self.theSegment.momentary = NO;
	self.theSegment.selectedSegmentIndex = 0;
	for (int i = 0; i < 3; i++)
		[self.theSegment setWidth:60.0 forSegmentAtIndex:i];
	[self.theSegment addTarget:self action:@selector(infoSwapped) forControlEvents:UIControlEventValueChanged];
	NSArray *toolbarItems = [NSArray arrayWithObjects:
							 spacer,
							 [[[UIBarButtonItem alloc] initWithCustomView:self.theSegment] autorelease], 
							 spacer, nil];
	self.toolbarItems = toolbarItems;
	[theSegment release];
	[spacer release];
	self.navigationController.toolbarHidden = NO;
	
	//corners and borders to avatar image
	CALayer * l = [theAvatar layer];
	l.cornerRadius = 5.0;
	l.masksToBounds = YES;
	l.borderColor = [UIColor darkGrayColor].CGColor;
	l.borderWidth = 1.0;	
	
	// And register to be notified for shaking and busy/not busy of Meemi session
	if([Meemi isBusy])
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadUser:) name:kNowFree object:nil];
	else
		[self loadUser:nil];
}

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	ourPersonalMeemi.delegate = nil;
	[ourPersonalMeemi release];
	ourPersonalMeemi = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
