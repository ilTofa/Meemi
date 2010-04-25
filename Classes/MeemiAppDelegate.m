//
//  MeemiAppDelegate.m
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//  Copyright Giacomo Tufano (gt@ilTofa.it) 2010. All rights reserved.
//

#import "MeemiAppDelegate.h"
#import "Meemi.h"
#import "FlurryAPI.h"

@implementation MeemiAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize urlToBeLoaded;

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store         
 coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in    
 application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] 
											   stringByAppendingPathComponent: @"Core_Data.sqlite"]];
	NSLog(@"store is on %@", [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"Core_Data.sqlite"]);
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] 
								  initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
												  configuration:nil URL:storeUrl options:nil error:&error]) {
		/*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should 
		 not use this function in a shipping application, although it may be useful during 
		 development. If it is not possible to recover from the error, display an alert panel that 
		 instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object 
		 model
		 Check the error message to determine what the actual problem was.
		 */
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}    
	
	return persistentStoreCoordinator;
}

-(void)removeCoreDataStore
{
	NSError *error;
	if(![[NSFileManager defaultManager] removeItemAtPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"Core_Data.sqlite"]
												   error:&error])
	{
		NSLog(@"Error in removeCoreDataStore: %@", error);
		UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
															message:[error localizedDescription]
														   delegate:nil
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil] 
								 autorelease];
		[theAlert show];
	}
	else
	{
		NSLog(@"Store deleted, exiting application");
		UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Quitting"
															message:@"Store deleted, exiting application"
														   delegate:nil
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil] 
								 autorelease];
		[theAlert show];
		abort();
	}
}
	   
#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

#pragma mark -
#pragma mark Exception Handler
void uncaughtExceptionHandler(NSException *exception) 
{
	[FlurryAPI logError:@"Uncaught exception." message:@"Crash!" exception:exception];
}                                       

#pragma mark -
#pragma mark Standard

// Register user default
+ (void)initialize
{	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDate *tempDate = [NSDate distantPast];
	NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"screenName", @"", @"password", 
								 0, @"userValidated", 0, @"userDeny", 100, "rowNumber", 24, "memeTime", 
								 tempDate, @"lastRead", nil];
    [defaults registerDefaults:appDefaults];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{
	NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
	[FlurryAPI startSession:@"K26CYXQMYFKM84B13825"];
	
    // Add the tab bar controller's current view as a subview of the window
	[window addSubview:tabBarController.view];

	// Start location request
	[[Meemi sharedSession] startLocation];

	// Setup CoreData and pass info to Meemi singleton.
    NSManagedObjectContext *context = [self managedObjectContext];
    if (!context) {
        // Handle the error.
    }
    [Meemi sharedSession].managedObjectContext = context;
	
	// reset mobileweb to goto home
	self.urlToBeLoaded = @"";
	
	// If use is validated, start on first tab, else on settings.
	if([[NSUserDefaults standardUserDefaults] integerForKey:@"userValidated"])
	{
		[[Meemi sharedSession] startSessionFromUserDefaults];
		self.tabBarController.selectedIndex = 0;
	}
	else
		self.tabBarController.selectedIndex = kSettingsTab;
}

- (void)applicationWillTerminate:(UIApplication *)application 
{	
    NSError *error;
    if (managedObjectContext != nil) 
	{
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) 
		{
			// Handle error
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
        } 
    }
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


- (void)dealloc 
{
    [managedObjectContext release];
    [managedObjectModel release];
    [persistentStoreCoordinator release];
    
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end

