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

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	DLog(@"shouldStartLoadWithRequest: <%@>", [[request URL] absoluteString]);
	// if it's a reply...
	if([[[request URL] absoluteString] rangeOfString:@"#myreply"].location != NSNotFound)
	{
		// Look for the last '/'
		NSRange theMemeRange;
		theMemeRange.location = [[[request URL] absoluteString] rangeOfString:@"/" options:NSBackwardsSearch].location + 1;
		theMemeRange.length = [[[request URL] absoluteString] rangeOfString:@"#myreply"].location - theMemeRange.location;
		NSString *temp = [NSString stringWithFormat:@"Should start reply to <%@>", [[[request URL] absoluteString] substringWithRange:theMemeRange]];
		UIAlertView *WOW =  [[UIAlertView alloc] initWithTitle:@"Reply"
													   message:temp
													  delegate:self
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil];
		[WOW show];
		[WOW release];
		NSLog(@"Got a meme reply to <%@>", [[[request URL] absoluteString] substringWithRange:theMemeRange]);
		//		return NO;
	}
	return YES;
}

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
	UIAlertView *noWay = [[UIAlertView alloc] initWithTitle:@"ERROR"
													message:[error localizedDescription]
												   delegate:self
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[noWay show];
	[noWay release];
}

-(IBAction)done:(id)sender
{
	
}

-(void)loadMemePage
{
	[self.laRuota startAnimating];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.urlToBeLoaded]];
	[self.theView loadRequest:request];	
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	// Init username and password
	// Set delegate of web view to us
	self.theView.delegate = self;

	[self loadMemePage];	
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
