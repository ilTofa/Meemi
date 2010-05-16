//
//  UserProfile.m
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "UserProfile.h"
#import "MemeOnWeb.h"

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
			dateFormatter = [[NSDateFormatter alloc] init];
			[dateFormatter setLocale:[NSLocale currentLocale]];
			[dateFormatter setDateStyle:NSDateFormatterLongStyle];
			[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
			birthday = [dateFormatter stringFromDate:theUser.birth];
			[dateFormatter release];			
			info.text = [NSString stringWithFormat:@"\nBorn %@\n\nFollows: %d\nFollowed: %d\n\n%@\n%@",
						 birthday,
						 [theUser.qta_followings intValue], [theUser.qta_followers intValue],
						 [theUser.follow_you boolValue] ? @"He/She follows you" : @"He/she don't follow you",
						 [theUser.you_follow boolValue] ? @"You follow him/her" : @"You don't follow him/her"];
			info.textAlignment = UITextAlignmentCenter;
			followButton.hidden = NO;
			[followButton setTitle:[theUser.you_follow boolValue] ? @"Unfollow" : @"Follow" forState:UIControlStateNormal];
			messageButton.hidden = NO;
			break;
	}
}

-(void)loadTextInView
{
	// Text
	screenName.text = theUser.screen_name;
	realName.text = theUser.real_name;
	location.text = theUser.current_location;
	info.text = theUser.info;
	// Image
	[theAvatar setBackgroundImage:[UIImage imageWithData:theUser.avatar] forState:UIControlStateNormal];
	[self infoSwapped];
}

-(void)loadUser:(NSNotification *)note
{
	DLog(@"Now loading user info");
	[Meemi sharedSession].delegate = self;
	[[Meemi sharedSession] getUser:theUser.screen_name];
}

-(IBAction)followUnfollow:(id)sender
{
	DLog(@"Now %@ user", [theUser.you_follow boolValue] ? @"unfollowing" : @"following");
	[Meemi sharedSession].delegate = self;
	if([theUser.you_follow boolValue])
		[[Meemi sharedSession] unfollowUser:theUser.screen_name];	
	else
		[[Meemi sharedSession] followUser:theUser.screen_name];	
}

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error
{
	UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
														message:@"Error loading data, please try again later"
													   delegate:nil
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil] 
							 autorelease];
	[theAlert show];
}	

-(void)meemi:(MeemiRequest)request didFinishWithResult:(MeemiResult)result
{
	DLog(@"got info (or followed/unfollowed), reloading the user. New infos are: %@", self.theUser);
	if(result == MmFollowOK)
		theUser.you_follow = [NSNumber numberWithBool:YES];
	if(result == MmUnfollowOK)
		theUser.you_follow = [NSNumber numberWithBool:NO];
	if(request == MMGetNewUser)
	{ //update and reload avatar, just in case...
		[self loadTextInView];
		[Meemi sharedSession].delegate;
		[[Meemi sharedSession] loadAvatar:theUser.screen_name];
	}
	// It could be MmGetNewUsers (then load the text, and do it on the main thread!).
	[self performSelectorOnMainThread:@selector(loadTextInView) withObject:nil waitUntilDone:NO];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	[self loadTextInView];
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	// Setup toolbar
	UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	NSArray *tempStrings = [NSArray arrayWithObjects:@"Info", @"Profile", @"Extra", nil];
	self.theSegment = [[UISegmentedControl alloc] initWithItems:tempStrings];
	self.theSegment.segmentedControlStyle = UISegmentedControlStyleBar;
	// That's 138, 176, 218 "meemi chiaro"
	theSegment.tintColor = [UIColor colorWithRed:0.54118 green:0.6902 blue:0.8549 alpha:1.0];
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
	
	// And register to be notified for shaking and busy/not busy of Meemi session
	if([Meemi sharedSession].isBusy)
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadUser:) name:kNowFree object:nil];
	else
		[self loadUser:nil];
}

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if([Meemi sharedSession].delegate == self)
		[Meemi sharedSession].delegate = nil;
	self.navigationController.toolbarHidden = YES;
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
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
