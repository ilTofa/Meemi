//
//  SettingsController.m
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "SettingsController.h"
#import "MeemiAppDelegate.h"
#import "AboutBox.h"
#import "SFHFKeychainUtils.h"

@implementation SettingsController

@synthesize screenName, password, testLabel, laRuota, dismissButton;

-(void)restoreDefaults
{
	NSError *err;
	self.screenName.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"screenName"];
	self.password.text = [SFHFKeychainUtils getPasswordForUsername:self.screenName.text andServiceName:@"Meemi" error:&err];
}

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error
{
	if([laRuota isAnimating])
		[laRuota stopAnimating];
	NSLog(@"Error: %@", error);
	UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
														message:[error localizedDescription]
													   delegate:nil
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil] 
							 autorelease];
	[theAlert show];
}

-(void)meemi:(MeemiRequest)request didFinishWithResult:(MeemiResult)result
{
	// if it was an user validation request (as it should be) set the result
	if(request == MmRValidateUser)
		self.testLabel.text = [Meemi getResponseDescription:result];
	// If session is valid, save parameters into defaults
	if([Meemi isValid])
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:self.screenName.text forKey:@"screenName"];
		NSError *err;
		[SFHFKeychainUtils storeUsername:self.screenName.text andPassword:self.password.text 
						  forServiceName:@"Meemi" updateExisting:YES error:&err];
		[defaults setInteger:1 forKey:@"userValidated"];
		[[Meemi sharedSession] startSessionFromUserDefaults];
		self.dismissButton.enabled = YES;
		// and reload memes...
		[(MeemiAppDelegate *)[[UIApplication sharedApplication] delegate] reloadMemes];
	}
	else // restore base names and retry...
	{
		[self restoreDefaults];
		[self.screenName becomeFirstResponder];
		self.dismissButton.enabled = NO;
	}
	if([laRuota isAnimating])
		[laRuota stopAnimating];
}

-(void)setWatermark:(int)watermark
{ }

- (IBAction)testLogin:(id)sender
{
	DLog(@"testLogin called.");
	// call back us above.
	[laRuota startAnimating];
	[Meemi sharedSession].delegate = self;
	DLog(@"sharedSession is %@", [Meemi sharedSession]);
	[[Meemi sharedSession] validateUser:self.screenName.text usingPassword:self.password.text];
}

- (IBAction)aboutBox:(id)sender
{
	AboutBox *theBox = [[[AboutBox alloc] initWithNibName:@"AboutBox" bundle:nil] autorelease];
	theBox.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	[self presentModalViewController:theBox animated:YES]; 
}

- (IBAction)signupUser:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://meemi.com/p/signup"]];
}

- (IBAction)dismissSettings:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
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
	if([Meemi isValid])
	{
		[(MeemiAppDelegate *)[[UIApplication sharedApplication] delegate] reloadMemes];
		[self.navigationController popViewControllerAnimated:YES];
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
	self.navigationController.navigationBarHidden = YES;
	self.navigationController.toolbarHidden = YES;
	self.title = NSLocalizedString(@"Settings", @"");
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	// load user defaults
	[self restoreDefaults];
	// if user was not tested, test it
	if([[NSUserDefaults standardUserDefaults] integerForKey:@"userValidated"] == 0)
		[self testLogin:nil];
	else
		self.dismissButton.enabled = YES;
}

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
	// It happens that we don't need any callback from Meemi anymore.
	if([Meemi sharedSession].delegate == self)
		[Meemi sharedSession].delegate = nil;
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
