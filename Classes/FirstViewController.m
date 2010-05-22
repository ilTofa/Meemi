//
//  FirstViewController.m
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//  Copyright Giacomo Tufano (gt@ilTofa.it) 2010. All rights reserved.
//

#import "FirstViewController.h"

@implementation FirstViewController

@synthesize cameraButton;

#pragma mark ImageSenderControllerDelegate & TextSenderControllerDelegate

-(void)doneWithImageSender
{
	self.navigationController.navigationBarHidden = NO;
	[self.navigationController popViewControllerAnimated:NO];
}

-(void)doneWithTextSender
{
	self.navigationController.navigationBarHidden = NO;
	[self.navigationController popViewControllerAnimated:NO];
}


#pragma mark TheWorkflow

-(IBAction)sendImage:(id)sender
{
	// Here we have the picture in an UIImage. Show the controller for definitive sending.
	ImageSender *imageSenderController = [[ImageSender alloc] initWithNibName:@"ImageSender" bundle:nil];
	imageSenderController.delegate = self;
	[self.navigationController pushViewController:imageSenderController animated:YES];
	[imageSenderController release];
}

-(IBAction)sendText:(id)sender
{
	TextSender *textSenderController = [[TextSender alloc] initWithNibName:@"TextSender" bundle:nil];
	textSenderController.delegate = self;
	[self.navigationController pushViewController:textSenderController animated:YES];
	[textSenderController release];
}

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (void)viewDidLoad 
{
    [super viewDidLoad];
	// if no camera nor photo library gray button
	if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] && ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		self.cameraButton.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	self.navigationController.navigationBarHidden = NO;
	// If the session is invalid, goto setting page!
//	if(![Meemi sharedSession].isValid)
//		((MeemiAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.selectedIndex = kSettingsTab;	
}

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error
{
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
	if(request == MmGetNew)
	{
		NSLog(@"Received response from getNewMemes");
	}
}	

-(void)setWatermark:(int)watermark
{ }


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
