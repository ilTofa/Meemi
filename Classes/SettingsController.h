//
//  SettingsController.h
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Meemi.h"

@interface SettingsController : UIViewController <UITextFieldDelegate, MeemiDelegate>
{
	UITextField *screenName;
	UITextField *password;
	UITextField *rowNumber;
	UILabel *testLabel;
	UIActivityIndicatorView *laRuota;
}

@property (nonatomic, retain) IBOutlet UITextField *screenName;
@property (nonatomic, retain) IBOutlet UITextField *password;
@property (nonatomic, retain) IBOutlet UITextField *rowNumber;
@property (nonatomic, retain) IBOutlet UILabel *testLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *laRuota;

- (IBAction)testLogin:(id)sender;
- (IBAction)aboutBox:(id)sender;
- (IBAction)killDB:(id)sender;
- (IBAction)dismiss:(id)sender;

@end
