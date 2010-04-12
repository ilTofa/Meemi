//
//  ImageSender.h
//  Meemi
//
//  Created by Giacomo Tufano on 20/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Meemi.h"

@protocol ImageSenderControllerDelegate

-(void)doneWithImageSender;

@end


@interface ImageSender : UIViewController <MeemiDelegate, UITextFieldDelegate>
{
	UITextField *description;
	UITextField *locationLabel;
	UIImageView *theImageView;
	UIImage *theImage, *theThumbnail;
	UIActivityIndicatorView *laRuota;
	UISwitch *highResWanted;
	UISwitch *wantSave;
	id<ImageSenderControllerDelegate> delegate;
	BOOL comesFromCamera;
}

@property (retain, nonatomic) IBOutlet UITextField *description;
@property (retain, nonatomic) IBOutlet UITextField *locationLabel;
@property (retain, nonatomic) IBOutlet UIImageView *theImageView;
@property (retain, nonatomic) IBOutlet UIImage *theImage;
@property (retain, nonatomic) IBOutlet UIImage *theThumbnail;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *laRuota;
@property (retain, nonatomic) IBOutlet UISwitch *highResWanted;
@property (retain, nonatomic) IBOutlet UISwitch *wantSave;
@property (assign) BOOL comesFromCamera;
@property (assign) id<ImageSenderControllerDelegate> delegate;

-(IBAction)sendIt:(id)sender;
-(IBAction)cancel:(id)sender;

@end
