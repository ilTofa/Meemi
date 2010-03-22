//
//  FirstViewController.h
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//  Copyright Giacomo Tufano (gt@ilTofa.it) 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>

#import "MeemiAppDelegate.h"
#import "Meemi.h"
#import "ImageSender.h"

@interface FirstViewController : UIViewController <UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, 
													ImageSenderControllerDelegate>
{
	UIButton *cameraButton;
	ImageSender *imageSenderController;
}

@property (retain, nonatomic) IBOutlet UIButton *cameraButton;

-(IBAction)sendImage:(id)sender;
-(IBAction)sendText:(id)sender;

-(void)showMediaPickerFor:(UIImagePickerControllerSourceType)type;

@end
