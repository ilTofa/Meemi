//
//  MemeOnWeb.m
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "MemeOnWeb.h"

@implementation MemeOnWeb

@synthesize theView, laRuota, urlToBeLoaded;

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
		UIAlertView *noWay = [[UIAlertView alloc] initWithTitle:@"ERROR"
														message:[error localizedDescription]
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[noWay show];
		[noWay release];
	}
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
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
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
