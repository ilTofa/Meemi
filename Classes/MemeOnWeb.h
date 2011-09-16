//
//  MemeOnWeb.h
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
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

@end
