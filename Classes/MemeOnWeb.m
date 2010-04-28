//
//  MemeOnWeb.m
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "MemeOnWeb.h"

@implementation MemeOnWeb

@synthesize theView, laRuota, urlToBeLoaded, replyTo, replyScreenName;

#pragma mark UIWebViewDelegate

// TODO: look into http://www.quackit.com/css/properties/css_table-layout.cfm

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
//		NSString *temp = [NSString stringWithFormat:@"Should start reply to <%@>", [[[request URL] absoluteString] substringWithRange:theMemeRange]];
//		UIAlertView *WOW =  [[UIAlertView alloc] initWithTitle:@"Reply"
//													   message:temp
//													  delegate:self
//											 cancelButtonTitle:@"OK"
//											 otherButtonTitles:nil];
//		[WOW show];
//		[WOW release];
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

#pragma mark ImageSenderControllerDelegate & TextSenderControllerDelegate

//-(void)doneWithImageSender
//{
//	[imageSenderController.view removeFromSuperview];
//	[imageSenderController release];
//}

-(void)doneWithTextSender
{
	self.navigationController.navigationBarHidden = NO;
	[self.navigationController popViewControllerAnimated:YES];
	// reload to get new meme
	[self loadMemePage];
}

-(void)doneWithImageSender
{
	[self doneWithTextSender];
}

#pragma mark Reply and Reload

-(IBAction)replyToMeme:(id)sender
{
	DLog(@"replyToMeme: called");
	// Now check we are still in the same page
	if(([[[self.theView.request URL] absoluteString] rangeOfString:[self.replyTo stringValue]]).location == NSNotFound)
	{
		UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Sorry" 
															message:@"The current meme is not the original one. Shake to reload" 
														   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] 
								 autorelease];
		[theAlert show];
		return;
	}
	// Make user choose if (s)he wants to reply with text or image
	UIActionSheet *chooseIt = [[[UIActionSheet alloc] initWithTitle:@"Reply with?" 
														   delegate:self 
												  cancelButtonTitle:@"Cancel"
											 destructiveButtonTitle:nil
												  otherButtonTitles:@"Text", @"Image", nil]
							   autorelease];
	[chooseIt showFromTabBar:(UITabBar *)[((MeemiAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController view]];
	// Flows below to the ActionSheetDelegate function.
}	

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

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSLog(@"Picked button #%d", buttonIndex);
	if(buttonIndex == 0) // Text
	{
		TextSender *controller = [[TextSender alloc] initWithNibName:@"TextSender" bundle:nil];
		controller.delegate = self;
		controller.replyTo = self.replyTo;
		controller.replyScreenName = self.replyScreenName;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else if(buttonIndex == 1) // Image
	{
		ImageSender *controller = [[ImageSender alloc] initWithNibName:@"ImageSender" bundle:nil];
		controller.delegate = self;
		controller.replyTo = self.replyTo;
		controller.replyScreenName = self.replyScreenName;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
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
	// Add a right button for reply to the meme list
	UIBarButtonItem *replyButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
																				  target:self 
																				  action:@selector(replyToMeme:)];
	self.navigationItem.rightBarButtonItem = replyButton;
	[replyButton release];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	ALog(@"Thread for meme %@. URL is %@", self.replyTo, self.urlToBeLoaded);
	// Set delegate of web view to us
	self.theView.delegate = self;
	[self loadMemePage];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceShaken:) name:@"deviceShaken" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
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
