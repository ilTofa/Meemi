//
//  MeemiAppDelegate.m
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//  Copyright Giacomo Tufano (gt@ilTofa.it) 2010. All rights reserved.
//

#import "MeemiAppDelegate.h"
#import "Meemi.h"

@implementation MeemiAppDelegate

@synthesize window;
@synthesize tabBarController;

// Register user default
+ (void)initialize
{	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"screenName", @"", @"password", 
								 0, @"userValidated", 0, @"userDeny", nil];
    [defaults registerDefaults:appDefaults];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{    
    // Add the tab bar controller's current view as a subview of the window
    [window addSubview:tabBarController.view];
	// Start location request
	[[Meemi sharedSession] startLocation];
	// If use is validated, start on first tab, else on settings.
	if([[NSUserDefaults standardUserDefaults] integerForKey:@"userValidated"])
	{
		[[Meemi sharedSession] startSessionFromUserDefaults];
		self.tabBarController.selectedIndex = 0;
	}
	else
		self.tabBarController.selectedIndex = 2;
}


/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
}
*/

/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}
*/


- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end

