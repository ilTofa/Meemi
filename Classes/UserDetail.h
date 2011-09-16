//
//  UserDetail.h
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
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
