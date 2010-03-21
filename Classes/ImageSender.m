//
//  ImageSender.m
//  Meemi
//
//  Created by Giacomo Tufano on 20/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "ImageSender.h"


@implementation ImageSender

@synthesize description, theImage, theThumbnail, theImageView, laRuota;

// make a scaled copy (constrained to targetSize size) of self.theImage into self.theThumbnail for display purpose
-(void)createThumbnail;
{
	// Calculate new dmension without deforming the image
	CGFloat targetWidth = 128.0;
	CGFloat targetHeight = 128.0;
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
	UIImage *tempImage = [UIImage imageWithCGImage:theImage.CGImage];
	[tempImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	// Get the new image from the context
	self.theThumbnail = UIGraphicsGetImageFromCurrentImageContext();
	// End the context
	UIGraphicsEndImageContext();
}


-(IBAction)sendIt:(id)sender
{
}

-(IBAction)cancel:(id)sender
{
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
	[self createThumbnail];
	self.theImageView.image = self.theThumbnail;
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
