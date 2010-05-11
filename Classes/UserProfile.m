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

@synthesize theAvatar, screenName, realName, birth, location, info, theSegment, followButton;
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

-(IBAction)infoSwapped
{
	switch (self.theSegment.selectedSegmentIndex) 
	{
		case 0:
			info.text = theUser.info;
			info.textAlignment = UITextAlignmentLeft;
			followButton.hidden = YES;
			break;
		case 1:
			info.text = theUser.profile;
			info.textAlignment = UITextAlignmentLeft;
			followButton.hidden = YES;
			break;
		default:
			info.text = [NSString stringWithFormat:@"Follows: %d\nFollowed: %d\n\n%@\n%@",
						 [theUser.qta_followings intValue], [theUser.qta_followers intValue],
						 [theUser.follow_you boolValue] ? @"He/She follows you" : @"He/she don't follow you",
						 [theUser.you_follow boolValue] ? @"You follow him/her" : @"You don't follow him/her"];
			info.textAlignment = UITextAlignmentCenter;
			followButton.hidden = NO;
			[followButton setTitle:[theUser.you_follow boolValue] ? @"Unfollow" : @"Follow" forState:UIControlStateNormal];
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
	// dates...
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[NSLocale currentLocale]];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	birth.text = [dateFormatter stringFromDate:theUser.birth];
	[dateFormatter release];
	// Image
	[theAvatar setImage:[UIImage imageWithData:theUser.avatar] forState:UIControlStateNormal];
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
	[self loadTextInView];
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
