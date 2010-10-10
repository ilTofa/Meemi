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

@interface WithFriendsController : UITableViewController <NSFetchedResultsControllerDelegate, MeemiDelegate, TextSenderControllerDelegate, ImageSenderControllerDelegate, UIActionSheetDelegate, UISearchBarDelegate>
{
	NSFetchedResultsController *theMemeList;
	UITableViewCell *memeCell;
	NSString *predicateString;
	FetchTypes currentFetch;
	// Is this the "main list", or a detail? :)
	NSNumber *replyTo;
	NSString *replyScreenName;
	NSNumber *replyQuantity;
	int readMemes;
	// Scrolling
	BOOL checkForRefresh;
	BOOL enoughDragging;
	UIView *headerView;
	UILabel *headerLabel;
	UILabel *headerArrow;
	UIActivityIndicatorView *laRuota;
	UIActivityIndicatorView *laPiccolaRuota;
	UIButton *reloadButtonInBreakTable;
	Meemi *ourPersonalMeemi;
	Meemi *privateFetchMeemi;
	Meemi *mentionFetchMeemi;
	// the search bar
	UISearchBar *theSearchBar;
	BOOL barPresent;
	NSString *searchString;
	NSInteger searchScope;
	// Other
	int watermark;
	BOOL specialThread;
	// UIImage caches
	UIImage *imgCamera;
	UIImage *imgVideo;
	UIImage *imgLink;
	UIImage *imgBlackFlag;
	UIImage *imgWhiteFlag;
	UIImage *imgNothing;
	UIImage *imgSemplice;
	UIImage *imgLock;
	UIImage *imgStar;
	BOOL thatsTheMemeKindChoice;
}

-(IBAction)filterSelected;
-(IBAction)avatarTouched:(id)sender;

-(IBAction)loadMore:(id)sender;
-(IBAction)doNothing:(id)sender;

-(void)loadMemePage;
-(void)markReadMemes;

@property (nonatomic, assign) IBOutlet UITableViewCell *memeCell;
@property (nonatomic, assign) IBOutlet UIView *headerView;
@property (nonatomic, retain) IBOutlet UISearchBar *theSearchBar;
@property (nonatomic, retain) IBOutlet UILabel *headerLabel;
@property (nonatomic, retain) IBOutlet UILabel *headerArrow;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *laRuota;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *laPiccolaRuota;
@property (nonatomic, retain) IBOutlet UIButton *reloadButtonInBreakTable;
@property (nonatomic, retain) NSString *predicateString;
@property (nonatomic, retain) NSNumber *replyTo;
@property (nonatomic, retain) NSString *replyScreenName;
@property (nonatomic, retain) NSNumber *replyQuantity;
@property (nonatomic, retain) NSString *searchString;
@property (nonatomic, assign) NSInteger searchScope;

@end
