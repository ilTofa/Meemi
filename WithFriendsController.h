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
	// Current position, for reloading. :)
	NSIndexPath *currentPosition;
	// Scrolling
	BOOL checkForRefresh;
	BOOL enoughDragging;
	UIView *headerView;
	UILabel *headerLabel;
	UILabel *headerArrow;
	UIActivityIndicatorView *laRuota;
}

-(IBAction)filterSelected;
-(IBAction)avatarTouched:(id)sender;

-(IBAction)loadMore:(id)sender;

@property (nonatomic, assign) IBOutlet UITableViewCell *memeCell;
@property (nonatomic, assign) IBOutlet UIView *headerView;
@property (nonatomic, retain) IBOutlet UILabel *headerLabel;
@property (nonatomic, retain) IBOutlet UILabel *headerArrow;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *laRuota;
@property (nonatomic, retain) NSString *predicateString;
@property (nonatomic, retain) NSString *searchString;
@property (nonatomic, retain) NSNumber *replyTo;
@property (nonatomic, retain) NSString *replyScreenName;
@property (nonatomic, retain) NSIndexPath *currentPosition;

@end
