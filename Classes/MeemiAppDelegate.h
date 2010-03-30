//
//  MeemiAppDelegate.h
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//  Copyright Giacomo Tufano (gt@ilTofa.it) 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MeemiAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> {
    UIWindow *window;
    UITabBarController *tabBarController;
	// CoreData helpers
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;       
	NSPersistentStoreCoordinator *persistentStoreCoordinator;	
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
// CoreData helpers
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSString *applicationDocumentsDirectory;

@end
