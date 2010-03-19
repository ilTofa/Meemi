//
//  SettingsController.m
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "SettingsController.h"
#import "MeemiAppDelegate.h"

@implementation SettingsController

@synthesize screenName, password, testLabel;

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error
{
	NSLog(@"Error: %@", error);
	UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
														message:[error localizedDescription]
													   delegate:nil
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil] autorelease];
	[theAlert show];
}

-(void)meemi:(MeemiRequest)request didFinishWithResult:(MeemiResult)result
{
	// if it was an user validation request and it was OK, save it
	if(request == MmRValidateUser && result == MmUserExists)
	{
		// TODO: check a login and save ONLY if successful
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:self.screenName.text forKey:@"screenName"];
		[defaults setObject:self.password.text forKey:@"password"];
		self.testLabel.text = [[Meemi sharedSession] getResponseDescription:result];
	}
	else {
		self.testLabel.text = [[Meemi sharedSession] getResponseDescription:result];
	}

}

- (IBAction)testLogin:(id)sender
{
	// call back us above.
	[Meemi sharedSession].delegate = self;
	[[Meemi sharedSession] validateUser:self.screenName.text usingPassword:self.password.text];
}

// dismiss keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
	NSLog(@"textFieldShouldReturn called");
    if (theTextField == self.screenName)
        [self.screenName resignFirstResponder];
    if (theTextField == self.password)
        [self.password resignFirstResponder];
	// Select POST TAB.
	((MeemiAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.selectedIndex = 0;
    return YES;
}


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (void)viewDidLoad 
{
    [super viewDidLoad];
	self.screenName.delegate = self.password.delegate = self;
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	// load user defaults
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.screenName.text = [defaults stringForKey:@"screenName"];
	self.password.text = [defaults stringForKey:@"password"];
	[self.screenName becomeFirstResponder];
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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
