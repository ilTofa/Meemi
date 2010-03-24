//
//  AboutBox.h
//  Meemi
//
//  Created by Giacomo Tufano on 24/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
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
