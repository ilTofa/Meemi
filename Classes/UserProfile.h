//
//  UserProfile.h
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "Meemi.h"

@interface UserProfile : UIViewController <MeemiDelegate>
{
	User *theUser;
	UIButton *theAvatar;
	UILabel *screenName, *realName, *birth, *location;
	UITextView *info;
	UISegmentedControl *theSegment;
	UIButton *followButton;
}

@property (nonatomic, retain) User *theUser;
@property (nonatomic, retain) IBOutlet UIButton *theAvatar;
@property (nonatomic, retain) IBOutlet UILabel *screenName;
@property (nonatomic, retain) IBOutlet UILabel *realName;
@property (nonatomic, retain) IBOutlet UILabel *birth;
@property (nonatomic, retain) IBOutlet UILabel *location;
@property (nonatomic, retain) IBOutlet UITextView *info;
@property (nonatomic, retain) IBOutlet UISegmentedControl *theSegment;
@property (nonatomic, retain) IBOutlet UIButton *followButton;

-(IBAction)infoSwapped;
-(IBAction)followUnfollow:(id)sender;
-(IBAction)loadAvatar:(id)sender;

@end
