//
//  ImageSender.m
//  Meemi
//
//  Created by Giacomo Tufano on 20/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "ImageSender.h"


@implementation ImageSender

@synthesize description, theImage, theThumbnail, theImageView, laRuota, highResWanted, delegate, canBeLocalized;

// dismiss keyboard
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
	NSLog(@"textFieldShouldReturn called");
    if (theTextField == self.description)
        [self.description resignFirstResponder];
	return YES;
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
	[self.delegate doneWithImageSender];
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
	[self.delegate doneWithImageSender];
}

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
	[self.laRuota startAnimating];
	[Meemi sharedSession].delegate = self;
	// If user wants low res, make a thumbnail.
	if(!self.highResWanted.isOn)
	{
		NSLog(@"Generating thumbnail for post");
		[self createThumbnail:kLowResolutionSize];
		[[Meemi sharedSession] postImageAsMeme:self.theThumbnail withDescription:self.description.text withLocalization:self.canBeLocalized.isOn];
	}
	else
	{
		// Workaround the Meemi bug on EXIF orientation flag
		[self removeOrientation];
		[[Meemi sharedSession] postImageAsMeme:self.theThumbnail withDescription:self.description.text withLocalization:self.canBeLocalized.isOn];
	//		[[Meemi sharedSession] postImageAsMeme:self.theImage withDescription:self.description.text withLocalization:self.canBeLocalized.isOn];
	}
}

-(IBAction)cancel:(id)sender
{
	[self.delegate doneWithImageSender];
}

-(void)handleGotLocalization:(NSNotification *)note
{
	// enable localization, 'cause we now have one
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
    [super viewDidLoad];
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
	if([[Meemi sharedSession].nearbyPlaceName isEqual:@""])
	{
		self.canBeLocalized.enabled = NO;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleGotLocalization:) name:kGotLocation object:nil];
	}
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
