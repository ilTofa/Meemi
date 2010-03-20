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

@synthesize screenName, password, testLabel, laRuota;

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error
{
	if([laRuota isAnimating])
		[laRuota stopAnimating];
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
	// if it was an user validation request (as it should be) set the result
	if(request == MmRValidateUser)
		self.testLabel.text = [[Meemi sharedSession] getResponseDescription:result];
	// If session is valid, save parameters into defaults
	if([Meemi sharedSession].isValid)
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:self.screenName.text forKey:@"screenName"];
		[defaults setObject:self.password.text forKey:@"password"];		
	}
	else
		[self.screenName becomeFirstResponder];
	if([laRuota isAnimating])
		[laRuota stopAnimating];
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
	// Select POST TAB (only if we have valid user and password)
	if([Meemi sharedSession].isValid)
	{
		((MeemiAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.selectedIndex = 0;
		return YES;
	}
	// else do not dismiss keyboard (and warn user)
	self.testLabel.text = NSLocalizedString(@"Please, select a valid user", @"");
	[theTextField becomeFirstResponder];
	return NO;
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
	[laRuota startAnimating];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	self.screenName.text = [defaults stringForKey:@"screenName"];
	self.password.text = [defaults stringForKey:@"password"];;
	[self testLogin:nil];
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
