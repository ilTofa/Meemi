//
//  FirstViewController.h
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//  Copyright Giacomo Tufano (gt@ilTofa.it) 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Meemi.h"
#import "ImageSender.h"
#import "TextSender.h"


@interface FirstViewController : UIViewController <ImageSenderControllerDelegate, TextSenderControllerDelegate, MeemiDelegate>
{
	UIButton *cameraButton;
}

@property (retain, nonatomic) IBOutlet UIButton *cameraButton;

-(IBAction)sendImage:(id)sender;
-(IBAction)sendText:(id)sender;


@end
