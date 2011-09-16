//
//  MemeOnWeb.m
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "MemeOnWeb.h"

@implementation MemeOnWeb

@synthesize theView, laRuota, urlToBeLoaded;

- (void)loadInSafari
{
	[[UIApplication sharedApplication] openURL:self.theView.request.URL];
	
}

#pragma mark UIWebViewDelegate

// TODO: look into http://www.quackit.com/css/properties/css_table-layout.cfm

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	DLog(@"webViewDidFinishLoad");
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	if([self.laRuota isAnimating])
		[self.laRuota stopAnimating];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	DLog(@"webViewDidStartLoad");
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// Ignore NSAsyncLoadCancelled, because it seems an overkill to tell user of it.
	if([error code] != -999)
	{
		UIAlertView *noWay = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
														message:[error localizedDescription]
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[noWay show];
		[noWay release];
	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark Reload

-(void)loadMemePage
{
	[self.laRuota startAnimating];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.urlToBeLoaded]];
	[self.theView loadRequest:request];	
}

-(void)deviceShaken:(NSNotification *)note
{
	DLog(@"SHAKED!");
	[self loadMemePage];
}

#pragma mark Standard Stuff

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	UIBarButtonItem *safariButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Compass"] 
																	 style:UIBarButtonItemStylePlain 
																	target:self 
																	action:@selector(loadInSafari)];
	self.navigationItem.rightBarButtonItem = safariButton;
	[safariButton release];	
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.navigationController.toolbarHidden = YES;
	DLog(@"URL is %@", self.urlToBeLoaded);
	// Set delegate of web view to us
	self.theView.delegate = self;
	self.theView.scalesPageToFit = YES;
	[self loadMemePage];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceShaken:) name:@"deviceShaken" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
	self.theView.delegate = nil;
	[self.theView stopLoading];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

// This view will autorotate!
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return YES;
}

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
