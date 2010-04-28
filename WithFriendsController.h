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
	FTAll = 0,
	FTNew,
	FTPvt,
	FTMentions
} FetchTypes;

@interface WithFriendsController : UITableViewController <NSFetchedResultsControllerDelegate, UISearchBarDelegate>
{
	NSFetchedResultsController *theMemeList;
	UITableViewCell *memeCell;
	NSString *predicateString;
	NSString *searchString;
	FetchTypes currentFetch;
}

-(IBAction)filterSelected;

@property (nonatomic, assign) IBOutlet UITableViewCell *memeCell;
@property (nonatomic, retain) NSString *predicateString;
@property (nonatomic, retain) NSString *searchString;

@end
