//
//  MeemiAppDelegate.h
//  Meemi
//
//  Created by Giacomo Tufano on 17/03/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>
#import "Meemi.h"

#define kSettingsTab 3
#define kWebTab 4

@interface MeemiAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, UIAlertViewDelegate> 
{
    UIWindow *window;
    UINavigationController *navigationController;
	// CoreData helpers
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;       
	NSPersistentStoreCoordinator *persistentStoreCoordinator;
	// Mobileweb navigation helper...
	NSString *urlToBeLoaded;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
// CoreData helpers
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, readonly) NSString *applicationDocumentsDirectory;
// Mobileweb navigation helper...
@property (nonatomic, retain) NSString *urlToBeLoaded;

-(void)removeCoreDataStore;
-(void)reloadMemes;
-(void)markReadMemes;


@end
