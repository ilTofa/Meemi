//
//  ImageSender.m
//  Meemi
//
//  Created by Giacomo Tufano on 20/03/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "ImageSender.h"


@implementation ImageSender

@synthesize description, theImage, theThumbnail, theImageView, laRuota, highResWanted, wantSave; 
@synthesize delegate, locationLabel, comesFromCamera, replyTo, replyScreenName;

#pragma mark UITextFieldDelegate

// dismiss keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
	NSLog(@"textFieldShouldReturn called");
	[theTextField resignFirstResponder];
	return YES;
}

#pragma mark MeemiDelegate

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error
{
	if([laRuota isAnimating])
		[laRuota stopAnimating];
	NSLog(@"Error: %@", error);
	UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
														message:[error localizedDescription]
													   delegate:nil
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil] 
							 autorelease];
	[theAlert show];
	[self.delegate doneWithImageSender];
}

-(void)meemi:(MeemiRequest)request didFinishWithResult:(MeemiResult)result
{
	// if error, tell user.
	if(result != MmPostOK)
	{
		UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
															message:[Meemi getResponseDescription:result]
														   delegate:nil
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil] 
								 autorelease];
		[theAlert show];
	}
	if([laRuota isAnimating])
		[laRuota stopAnimating];
	[self.delegate doneWithImageSender];
}

-(void)setWatermark:(int)watermark
{ }

#pragma mark Image scaling

// make a scaled copy (constrained to targetSize size) of self.theImage into self.theThumbnail for display purpose
-(void)createThumbnail:(CGFloat) ofSize
{
	// Calculate new dmension without deforming the image
	CGFloat targetWidth = ofSize;
	CGFloat targetHeight = ofSize;
	CGSize targetSize = CGSizeMake(targetWidth, targetHeight);
	CGFloat scaleFactor = 0.0;
	CGFloat scaledWidth = targetWidth;
	CGFloat scaledHeight = targetHeight;
	CGSize imageSize = self.theImage.size;
	
	if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
	{
        CGFloat widthFactor = targetWidth / imageSize.width;
        CGFloat heightFactor = targetHeight / imageSize.height;
		
        if (widthFactor < heightFactor) 
			scaleFactor = widthFactor; // scale to fit height
        else 
			scaleFactor = heightFactor; // scale to fit width
		
        scaledWidth  = imageSize.width * scaleFactor;
        scaledHeight = imageSize.height * scaleFactor;
	}
	CGSize newSize = CGSizeMake(scaledWidth, scaledHeight);
	// Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
	// Tell the old image to draw in this new context, with the desired size
	[self.theImage drawInRect:CGRectMake(0, 0, scaledWidth, scaledHeight)];
	// Get the new image from the context
	self.theThumbnail = UIGraphicsGetImageFromCurrentImageContext();
	// End the context
	UIGraphicsEndImageContext();
}

// This is a workaround a bug in meemi.
-(void)removeOrientation
{
	// Create a graphics image context
    UIGraphicsBeginImageContext(self.theImage.size);
	// Tell the old image to draw in this new context, with the desired size
	[self.theImage drawInRect:CGRectMake(0, 0, self.theImage.size.width, self.theImage.size.height)];
	// Get the new image from the context
	self.theThumbnail = UIGraphicsGetImageFromCurrentImageContext();
	// End the context
	UIGraphicsEndImageContext();	
}

#define kImageSizeInNib 134.0
#define kLowResolutionSize 800.0

-(IBAction)sendIt:(id)sender
{
	// Dismiss keyboard if needed
	if([self.description isFirstResponder])
		[self.description resignFirstResponder];
	if(self.theImage == nil)
	{
		[self cancel:nil];
		return;
	}
	[self.laRuota startAnimating];
	// Save to camera roll if requested (and if photo comes from camera)
	if(self.wantSave && comesFromCamera) 
		UIImageWriteToSavedPhotosAlbum(self.theImage, nil, nil, nil);
	[Meemi sharedSession].delegate = self;
	// If user wants low res, make a thumbnail.
	BOOL canBeLocalized = !([self.locationLabel.text isEqualToString:@""]);
	if(!self.highResWanted.isOn)
	{
		NSLog(@"Generating thumbnail for post");
		[self createThumbnail:kLowResolutionSize];
	}
	else
	{
		// Workaround the Meemi bug on EXIF orientation flag
		[self removeOrientation];
	}
	// Send "edited" localization to session
	[Meemi setNearbyPlaceName:self.locationLabel.text];
    NSLog(@"image size: %.0fx%.0f", self.theThumbnail.size.height, self.theThumbnail.size.width);
	if(self.replyScreenName == nil)
		[[Meemi sharedSession] postImageAsMeme:self.theThumbnail withDescription:self.description.text withLocalization:canBeLocalized];
	else
		[[Meemi sharedSession] postImageAsReply:self.theThumbnail withDescription:self.description.text withLocalization:canBeLocalized 
									  replyWho:self.replyScreenName replyNo:replyTo];
		NSLog(@"send image on reply");
}

-(IBAction)cancel:(id)sender
{
	[self.delegate doneWithImageSender];
}

-(void)handleGotLocalization:(NSNotification *)note
{
	// enable localization, 'cause we now have one
	self.locationLabel.enabled = YES;
	DLog(@"Setting location.text to %@", [Meemi nearbyPlaceName]);
	self.locationLabel.text = [Meemi nearbyPlaceName];
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
    [super viewDidLoad];
	// Hide toolbar
	self.navigationController.navigationBarHidden = YES;
	self.navigationController.toolbarHidden = YES;
	// Protect from being recalled for a low memory condition
	if(self.theImage == nil)
	{
		// Restart localization
		[[Meemi sharedSession] startLocation];
		// What the client have?
		BOOL library = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary];
		BOOL camera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
		// if both, allow the user to choose between camera and library
		if(library && camera)
		{
			UIActionSheet *chooseIt = [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Image from?", @"")
																   delegate:self 
														  cancelButtonTitle:NSLocalizedString(@"Camera", @"")
													 destructiveButtonTitle:nil
														  otherButtonTitles:NSLocalizedString(@"Library", @""), nil]
									   autorelease];
			[chooseIt showInView:self.view];
		}
		else 
		{
			// use what client have
			if(library)
			{
				comesFromCamera = NO;
				[self showMediaPickerFor:UIImagePickerControllerSourceTypePhotoLibrary];
			}
			else if(camera)
			{
				comesFromCamera = YES;
				[self showMediaPickerFor:UIImagePickerControllerSourceTypeCamera];
			}
			else
				// TODO: gray Image button if no camera, nor library
				;
		}
	}
}

-(void)showMediaPickerFor:(UIImagePickerControllerSourceType)type
{
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.delegate = self;
	imagePicker.sourceType = type;
	[self presentModalViewController:imagePicker animated:YES];
	[imagePicker release];		
}

-(void)showImageSenderController
{
	self.description.delegate = self;
	CGSize imageSize = self.theImage.size;
	// Create a thumbnail to show image (if image is bigger than the bounding box)
	if(imageSize.width > kImageSizeInNib || imageSize.height > kImageSizeInNib)
		[self createThumbnail:kImageSizeInNib];
	// if image is smaller than low res for posting, disable highres switch
	if(imageSize.width < kLowResolutionSize && imageSize.height < kLowResolutionSize)
	{
		self.highResWanted.on = YES;
		self.highResWanted.enabled = NO;
	}
	self.theImageView.image = self.theThumbnail;
	// Disable localization if we don't have a position (but register to be notified)
	if([[Meemi nearbyPlaceName] isEqual:@""])
		self.locationLabel.enabled = NO;
	else
		self.locationLabel.text = [Meemi nearbyPlaceName];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGotLocalization:) name:kGotLocation object:nil];
	self.wantSave.enabled = self.comesFromCamera;
	self.wantSave.on = self.comesFromCamera;
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

- (void)viewDidUnload 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)dealloc {
    [super dealloc];
}


#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[laRuota stopAnimating];
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
        self.theImage = [info objectForKey:UIImagePickerControllerEditedImage];
        if (!self.theImage)
			self.theImage = [info objectForKey:UIImagePickerControllerOriginalImage];
		[self dismissModalViewControllerAnimated:YES];
		[self showImageSenderController];
    }
	else
	{
		// user don't want to do something, dismiss
		[self dismissModalViewControllerAnimated:YES];
		[self showImageSenderController];
	}
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissModalViewControllerAnimated:YES];
	[self showImageSenderController];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[laRuota startAnimating];
	NSLog(@"Picked button #%d", buttonIndex);
	if(buttonIndex == 0)
	{
		comesFromCamera = NO;
		[self showMediaPickerFor:UIImagePickerControllerSourceTypePhotoLibrary];
	}
	else
	{
		comesFromCamera = YES;
		[self showMediaPickerFor:UIImagePickerControllerSourceTypeCamera];
	}
}

@end
