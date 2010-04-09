//
//  WithFriendsController.h
//  Meemi
//
//  Created by Giacomo Tufano on 02/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Meemi.h"

@interface WithFriendsController : UITableViewController <NSFetchedResultsControllerDelegate, MeemiDelegate, UISearchBarDelegate>
{
	NSFetchedResultsController *theMemeList;
	UITableViewCell *memeCell;
}

@property (nonatomic, assign) IBOutlet UITableViewCell *memeCell;

-(IBAction)reloadMemes;

@end
