//
//  AboutBox.h
//  Meemi
//
//  Created by Giacomo Tufano on 24/03/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>


@interface AboutBox : UIViewController 
{
	UILabel *lVersion;
}

@property (nonatomic, retain) IBOutlet UILabel *lVersion;

-(IBAction)gotoWebSite:(id)sender;
-(IBAction)goBack:(id) sender;

@end
