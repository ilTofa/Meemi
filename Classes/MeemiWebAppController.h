//
//  MeemiWebAppController.h
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MeemiWebAppController : UIViewController  <UIWebViewDelegate>
{
	UIWebView *theView;
	NSString *screenName;
	NSString *password;
	UIActivityIndicatorView *laRuota;
}

@property (retain, nonatomic) IBOutlet UIWebView *theView;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *laRuota;
@property (retain, nonatomic) NSString *screenName;
@property (retain, nonatomic) NSString *password;

@end
