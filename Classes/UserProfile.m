//
//  UserProfile.m
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "UserProfile.h"

@implementation UserProfile

@synthesize theAvatar, screenName, realName, since, birth, location, info, theSegment;
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

-(IBAction)infoSwapped
{
	if(self.theSegment.selectedSegmentIndex == 0)
		info.text = theUser.info;
	else
		info.text = theUser.profile;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	// Text
	screenName.text = theUser.screen_name;
	realName.text = theUser.real_name;
	location.text = theUser.current_location;
	info.text = theUser.info;
	// dates...
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[NSLocale currentLocale]];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    since.text = [dateFormatter stringFromDate:theUser.since];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	birth.text = [dateFormatter stringFromDate:theUser.birth];
	[dateFormatter release];
	// Image
	theAvatar.image = [UIImage imageWithData:theUser.avatar];
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
