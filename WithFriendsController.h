//
//  WithFriendsController.h
//  Meemi
//
//  Created by Giacomo Tufano on 02/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Meemi.h"

typedef enum {
	FTAll = 1,
	FTNew,
	FTPvt,
	FTMentions
} FetchTypes;

@interface WithFriendsController : UITableViewController <NSFetchedResultsControllerDelegate, UISearchBarDelegate>
{
	NSFetchedResultsController *theMemeList;
	UITableViewCell *memeCell;
	NSString *filterString;
	FetchTypes currentFetch;
}

-(IBAction)filterSelected;

@property (nonatomic, assign) IBOutlet UITableViewCell *memeCell;

@end
