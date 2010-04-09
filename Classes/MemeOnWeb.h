//
//  MemeOnWeb.h
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MemeOnWeb : UIViewController <UIWebViewDelegate>
{
	NSString *urlToBeLoaded;
	UIWebView *theView;
	UIActivityIndicatorView *laRuota;
}

@property (retain, nonatomic) NSString *urlToBeLoaded;
@property (retain, nonatomic) IBOutlet UIWebView *theView;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *laRuota;

-(IBAction)done:(id)sender;

@end
