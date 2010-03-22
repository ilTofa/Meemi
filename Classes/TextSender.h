//
//  TextSender.h
//  Meemi
//
//  Created by Giacomo Tufano on 22/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Meemi.h"

@protocol TextSenderControllerDelegate

-(void)doneWithTextSender;

@end

@interface TextSender : UIViewController <MeemiDelegate>
{
	UITextView *description;
	UIActivityIndicatorView *laRuota;
	UISwitch *canBeLocalized;
	UITextField *channel;
	id<TextSenderControllerDelegate> delegate;
}

@property (retain, nonatomic) IBOutlet UITextView *description;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *laRuota;
@property (retain, nonatomic) IBOutlet UISwitch *canBeLocalized;
@property (retain, nonatomic) IBOutlet UITextField *channel;
@property (assign) id<TextSenderControllerDelegate> delegate;

-(IBAction)sendIt:(id)sender;
-(IBAction)cancel:(id)sender;

@end
