//
//  MemeOnWeb.h
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextSender.h"

@interface MemeOnWeb : UIViewController <UIWebViewDelegate, TextSenderControllerDelegate>
{
	NSString *urlToBeLoaded;
	UIWebView *theView;
	UIActivityIndicatorView *laRuota;
	TextSender *textSenderController;
	NSNumber *replyTo;
	NSString *replyScreenName;
}

@property (retain, nonatomic) NSString *urlToBeLoaded;
@property (retain, nonatomic) NSNumber *replyTo;
@property (retain, nonatomic) NSString *replyScreenName;
@property (retain, nonatomic) IBOutlet UIWebView *theView;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *laRuota;

-(IBAction)replyToMeme:(id)sender;
-(void)loadMemePage;

@end
