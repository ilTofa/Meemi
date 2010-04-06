//
//  TextSender.m
//  Meemi
//
//  Created by Giacomo Tufano on 22/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "TextSender.h"


@implementation TextSender

@synthesize description, laRuota, delegate, canBeLocalized, channel;


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
	[self.delegate doneWithTextSender];
}

-(void)meemi:(MeemiRequest)request didFinishWithResult:(MeemiResult)result
{
	// if error, tell user.
	if(result != MmPostOK)
	{
		UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
															message:[[Meemi sharedSession] getResponseDescription:result]
														   delegate:nil
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil] 
								 autorelease];
		[theAlert show];
	}
	if([laRuota isAnimating])
		[laRuota stopAnimating];
	[self.delegate doneWithTextSender];
}

-(IBAction)sendIt:(id)sender
{
	// Dismiss keyboard if needed
	if([self.description isFirstResponder])
		[self.description resignFirstResponder];
	if([self.channel isFirstResponder])
		[self.channel resignFirstResponder];
	[self.laRuota startAnimating];
	[Meemi sharedSession].delegate = self;
	[[Meemi sharedSession] postTextAsMeme:self.description.text withChannel:self.channel.text withLocalization:self.canBeLocalized.isOn];
}

-(IBAction)cancel:(id)sender
{
	[self.delegate doneWithTextSender];
}

-(void)handleGotLocalization:(NSNotification *)note
{
	// enable localization, 'cause we have one
	self.canBeLocalized.enabled = YES;
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


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	// Activate keyboard
    [super viewDidLoad];
	[self.description becomeFirstResponder];
	// Disable localization if we don't have a position (but register to be notified)
	if([[Meemi sharedSession].nearbyPlaceName isEqual:@""])
	{
		self.canBeLocalized.enabled = NO;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGotLocalization:) name:kGotLocation object:nil];
	}
	
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	// Restart localization
	[[Meemi sharedSession] startLocation];
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
