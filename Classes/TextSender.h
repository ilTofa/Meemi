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
	UITextField *channel;
	UITextField *locationLabel;
	id<TextSenderControllerDelegate> delegate;
	NSNumber *replyTo;
	NSString *replyScreenName;
	NSString *recipientNames;
	UILabel *privateMemeWarning;
}

@property (retain, nonatomic) IBOutlet UITextView *description;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *laRuota;
@property (retain, nonatomic) IBOutlet UITextField *channel;
@property (retain, nonatomic) IBOutlet UITextField *locationLabel;
@property (assign) id<TextSenderControllerDelegate> delegate;
@property (retain, nonatomic) NSNumber *replyTo;
@property (retain, nonatomic) NSString *replyScreenName;
@property (retain, nonatomic) NSString *recipientNames;
@property (retain, nonatomic) IBOutlet UILabel *privateMemeWarning;

-(IBAction)sendIt:(id)sender;
-(IBAction)cancel:(id)sender;

@end
