//
//  SettingsController.h
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SettingsController : UIViewController <UITextFieldDelegate>
{
	UITextField *screenName;
	UITextField *password;
	UILabel *testLabel;	
}

@property (nonatomic, retain) IBOutlet UITextField *screenName;
@property (nonatomic, retain) IBOutlet UITextField *password;
@property (nonatomic, retain) IBOutlet UILabel *testLabel;

- (IBAction)testLogin:(id)sender;

@end
