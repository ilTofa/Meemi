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



-(void)showImageSenderController:(UIImage *)theImage
{
	// Here we have the picture in an UIImage. Show the controller for definitive sending.
	imageSenderController = [[ImageSender alloc] initWithNibName:@"ImageSender" bundle:nil];
	imageSenderController.theImage = theImage;
	imageSenderController.delegate = self;
	[self.view addSubview:imageSenderController.view];
}

#pragma mark ImageSenderControllerDelegate & TextSenderControllerDelegate

-(void)doneWithImageSender
{
	[imageSenderController.view removeFromSuperview];
	[imageSenderController release];
}

-(void)doneWithTextSender
{
	[textSenderController.view removeFromSuperview];
	[textSenderController release];
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	// MediaType can be kUTTypeImage or kUTTypeMovie. If it's a movie then you
    // can get the URL to the actual file itself. This example only looks for images.
    NSLog(@"info: %@", info);
    NSString* mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    // NSString* videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
	
    // Try getting the edited image first. If it doesn't exist then you get the
    // original image.
    //
    if (CFStringCompare((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) 
	{
        UIImage* picture = [info objectForKey:UIImagePickerControllerEditedImage];
        if (!picture)
			picture = [info objectForKey:UIImagePickerControllerOriginalImage];
		[self dismissModalViewControllerAnimated:YES];
		[self showImageSenderController:picture];
    }
	else
		[self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSLog(@"Picked button #%d", buttonIndex);
	[self showMediaPickerFor:(buttonIndex == 0) ? UIImagePickerControllerSourceTypePhotoLibrary : UIImagePickerControllerSourceTypeCamera];
}

#pragma mark TheWorkflow

-(void)showMediaPickerFor:(UIImagePickerControllerSourceType)type
{
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.delegate = self;
	imagePicker.sourceType = type;
	[self presentModalViewController:imagePicker animated:YES];
	[imagePicker release];		
}

-(IBAction)sendImage:(id)sender
{
	// What the client have?
	BOOL library = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
	BOOL camera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
	// if both, allow the user to choose between camera and library
	if(library && camera)
	{
		UIActionSheet *chooseIt = [[UIActionSheet alloc] initWithTitle:@"Image from?"
															  delegate:self 
													 cancelButtonTitle:@"Camera"
												destructiveButtonTitle:nil
													 otherButtonTitles:@"Library", nil];
		[chooseIt showInView:self.view];
	}
	else 
	{
		// use what client have
		if(library)
			[self showMediaPickerFor:UIImagePickerControllerSourceTypePhotoLibrary];
		else if(camera)
			[self showMediaPickerFor:UIImagePickerControllerSourceTypeCamera];
		else
			// TODO: gray Image button if no camera, nor library
			;
	}
	
}

-(IBAction)sendText:(id)sender
{
	textSenderController = [[TextSender alloc] initWithNibName:@"TextSender" bundle:nil];
	textSenderController.delegate = self;
	[self.view addSubview:textSenderController.view];	
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

- (void)viewDidAppear
{
    [super viewDidLoad];
	// If the session is invalid, goto setting page!
	if(![Meemi sharedSession].isValid)
		((MeemiAppDelegate *)[[UIApplication sharedApplication] delegate]).tabBarController.selectedIndex = 2;	
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
