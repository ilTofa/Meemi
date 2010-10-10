//
//  UserDetail.h
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Meemi.h"

@interface UserDetail : UITableViewController <NSFetchedResultsControllerDelegate, MeemiDelegate>
{
	NSFetchedResultsController *theUserList;
	Meemi *ourPersonalMeemi;
	BOOL reloadInProgress;
}

@end
