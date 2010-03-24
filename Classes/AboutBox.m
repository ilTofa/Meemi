//
//  AboutBox.m
//  Meemi
//
//  Created by Giacomo Tufano on 24/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "AboutBox.h"


@implementation AboutBox

@synthesize lVersion;

-(IBAction)gotoWebSite:(id)sender
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.ilTofa.com/Meemi"]];
}

-(IBAction)goBack:(id) sender
{
	[self dismissModalViewControllerAnimated:YES];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Load localizations
	self.lVersion.text = [NSString stringWithFormat:NSLocalizedString(@"Version %@", @""),
						  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
	
}

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
