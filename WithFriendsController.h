//
//  WithFriendsController.h
//  Meemi
//
//  Created by Giacomo Tufano on 02/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Meemi.h"
#import "TextSender.h"
#import "ImageSender.h"

typedef enum {
	FTAll = 0,
	FTNew,
	FTPvt,
	FTSpecial,
	FTReplyView
} FetchTypes;

@interface WithFriendsController : UITableViewController <NSFetchedResultsControllerDelegate, MeemiDelegate, TextSenderControllerDelegate, ImageSenderControllerDelegate, UIActionSheetDelegate>
{
	NSFetchedResultsController *theMemeList;
	UITableViewCell *memeCell;
	NSString *predicateString;
	NSString *searchString;
	FetchTypes currentFetch;
	// Is this the "main list", or a detail? :)
	NSNumber *replyTo;
	NSString *replyScreenName;
}

-(IBAction)filterSelected;

@property (nonatomic, assign) IBOutlet UITableViewCell *memeCell;
@property (nonatomic, retain) NSString *predicateString;
@property (nonatomic, retain) NSString *searchString;
@property (nonatomic, retain) NSNumber *replyTo;
@property (nonatomic, retain) NSString *replyScreenName;

@end
