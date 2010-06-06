//
//  WithFriendsController.m
//  Meemi
//
//  Created by Giacomo Tufano on 02/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "WithFriendsController.h"
#import "MeemiAppDelegate.h"
#import "Meme.h"
#import "MemeOnWeb.h"
#import "UserProfile.h"
#import "SettingsController.h"

#import <QuartzCore/QuartzCore.h>
#import "RegexKitLite.h"

@implementation WithFriendsController

@synthesize memeCell, predicateString, replyTo, replyScreenName, replyQuantity;
@synthesize headerView, headerLabel, headerArrow, laRuota, laPiccolaRuota, reloadButtonInBreakTable;
@synthesize searchString, searchScope, theSearchBar;

-(void)setWatermark:(int)numberRead
{
	DLog(@"setWatermark: called with %d", numberRead);
	if(currentFetch == FTReplyView)
	{
		readMemes += numberRead;
		// In case of reply, if 20 read (a full page), and we're still not read all...
		// set the watermark to the first (because we're reading it backwards)
		if(numberRead == 20 && readMemes < [self.replyQuantity intValue])
			watermark = 1;
		else
			watermark = INT_MAX;
	}
	else
		watermark = numberRead;
}

-(int)watermark
{
	return watermark;
}

-(void)deviceShaken:(NSNotification *)note
{
	DLog(@"SHAKED!");
	// If session is not busy, reload.
	[self loadMemePage];
}

-(IBAction)loadMore:(id)sender
{
	DLog(@"loadMore: clicked");
	if(!ourPersonalMeemi)
	{
		ALog(@"*** Abnormal condition: loadMore: called without a valid ourPersonalMeemi. Reverting to a standard reload");
		ourPersonalMeemi = [[Meemi alloc] initFromUserDefault];
		if(!ourPersonalMeemi)
			ALog(@"Meemi session init failed. Shit...");
	}
	ourPersonalMeemi.delegate = self;
	if(currentFetch != FTReplyView)
		[ourPersonalMeemi getMemes];
	else
		[ourPersonalMeemi getMemeRepliesOf:self.replyTo screenName:self.replyScreenName total:[self.replyQuantity intValue]];
}

-(void)meemiIsBusy:(NSNotification *)note
{
	DLog(@"meemiIsBusy:");
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
	self.tableView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f, 0.0f);
	self.headerLabel.text = NSLocalizedString(@"Reloading...", @"");
	self.headerArrow.text = @" ";
	[UIView commitAnimations];	
	[self.laRuota startAnimating];
	[self.reloadButtonInBreakTable setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Nothing" ofType:@"png"]]
								   forState:UIControlStateNormal];
	[self.laPiccolaRuota startAnimating];
}

-(void)meemiIsFree:(NSNotification *)note
{
	DLog(@"meemiIsFree:");
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.4];
	self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
	[UIView commitAnimations];	
	[self.laRuota stopAnimating];
	[self.laPiccolaRuota stopAnimating];
	[self.reloadButtonInBreakTable setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"02-redo" ofType:@"png"]]
								   forState:UIControlStateNormal];
	self.headerLabel.text = NSLocalizedString(@"Pull down to Reload", @"");
	self.headerArrow.text = @"☟";
	[self.tableView reloadData];
}

-(void)mergeNewData:(NSNotification *)note
{
	DLog(@"Calling mergeChangesFromContextDidSaveNotification: on Meemi context");
	[[Meemi managedObjectContext] mergeChangesFromContextDidSaveNotification:note];
}

-(void)settingsView
{
	SettingsController *controller = [[SettingsController alloc] initWithNibName:@"SettingsController" bundle:nil];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
	controller = nil;	
}

-(IBAction)avatarTouched:(id)sender
{
	DLog(@"avatarTouched at row: %d", [[((UIButton *)sender) titleForState:UIControlStateNormal] integerValue]);
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[[((UIButton *)sender) titleForState:UIControlStateNormal] integerValue] 
												inSection:0];
	if(indexPath)
	{
		Meme *theFetchedMeme = [theMemeList objectAtIndexPath:indexPath];
		if(theFetchedMeme)
		{
			// Push user detail view
			UserProfile *detailViewController = [[UserProfile alloc] initWithNibName:@"UserProfile" bundle:nil];
			detailViewController.theUser = theFetchedMeme.user;
			// Pass the selected object to the new view controller.
			[self.navigationController pushViewController:detailViewController animated:YES];
			[detailViewController release];		
		}
	}
}

-(IBAction)doNothing:(id)sender
{
}

-(void)setupFetch
{
	NSManagedObjectContext *context = [Meemi managedObjectContext];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Configure the request's entity, and optionally its predicate.
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Meme" inManagedObjectContext:context];
	[fetchRequest setEntity:entityDescription];
	NSSortDescriptor *sortDescriptor;
	if(currentFetch == FTReplyView)
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date_time" ascending:YES];
	else
		sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dt_last_movement" ascending:NO];		
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	switch(currentFetch)
	{
		case FTAll:
			self.predicateString = @"reply_id == 0 AND private_meme == NO";
			break;
		case FTPvt:
			self.predicateString = [NSString stringWithFormat:@"private_meme == YES AND reply_id == 0"];
			break;
		case FTSpecial:
			self.predicateString = [NSString stringWithFormat:@"private_meme == NO AND special == YES and reply_id == 0"];
			break;
		case FTReplyView:
			self.predicateString = [NSString stringWithFormat:@"reply_id == %@ OR id == %@", self.replyTo, self.replyTo];
			break;
	}
	
	// Get (and add) search parameters if we have a search running
	if(![self.searchString isEqualToString:@""])
	{
		NSString *tempString;
		if(self.searchScope == 0)
		{
			DLog(@"searching on sender");
			tempString = [NSString stringWithFormat:@"%@ AND user.screen_name like[c] \"%@*\"", self.predicateString, self.searchString];
		}
		if(self.searchScope == 1)
		{
			DLog(@"searching on text");
			tempString = [NSString stringWithFormat:@"%@ AND content like[c] \"*%@*\"", self.predicateString, self.searchString];
		}
		if(self.searchScope == 2)
		{
			DLog(@"searching on channel");
			tempString = [NSString stringWithFormat:@"%@ AND channels like[c] \"%@*\"", self.predicateString, self.searchString];
		}
		self.predicateString = tempString;
	}

	DLog(@"In setupFetch. Type of fetch: %d. Filter: %@", currentFetch, self.predicateString);
	if(![self.predicateString isEqualToString:@""])
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:self.predicateString];
		[fetchRequest setPredicate:predicate];
	}
	[sortDescriptors release];
	[sortDescriptor release];
	
	if(theMemeList != nil)
	{
		theMemeList.delegate = nil;
		[theMemeList release];
		theMemeList = nil;
	}
	if(currentFetch == FTReplyView)
	{
		[NSFetchedResultsController deleteCacheWithName:@"ThreadCache"];
		theMemeList = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
														  managedObjectContext:context 
															sectionNameKeyPath:nil 
																	 cacheName:@"ThreadCache"];
	}
	else
	{
		[NSFetchedResultsController deleteCacheWithName:@"WithFriendsCache"];
		theMemeList = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
														  managedObjectContext:context 
															sectionNameKeyPath:nil 
																	 cacheName:@"WithFriendsCache"];
	}
	[fetchRequest release];
	theMemeList.delegate = self;
	
	NSError *error;
	if(![theMemeList performFetch:&error])
	{
		NSLog(@"Error in performFetch: %@", error);
		UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
															message:[error localizedDescription]
														   delegate:nil
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil] 
								 autorelease];
		[theAlert show];
	}
	[self.tableView reloadData];
	
	// If we're selecting the "private" view, it's time to reload
	// Alloc a new Meemi for that, and release it on return
	if(currentFetch == FTPvt)
	{
		// Setup the Meemi "agent"
		// If already existing, a query is still running, leave it alone
		if(privateFetchMeemi == nil)
		{
			privateFetchMeemi = [[Meemi alloc] initFromUserDefault];
			if(!privateFetchMeemi)
				ALog(@"Meemi privateFetch session init failed. Shit...");
			else
			{
				privateFetchMeemi.delegate = self;
				[privateFetchMeemi getMemePrivateReceived];
			}
		}
	}
}	

-(void)filterSelected
{
	currentFetch = ((UISegmentedControl *) (((UIBarButtonItem *)[self.toolbarItems objectAtIndex:2]).customView)).selectedSegmentIndex;
	DLog(@"in filterSelected for %d selected, filtering on '%@'", currentFetch, self.searchString);
	[self setupFetch];
}

-(void)loadMemePage
{
	DLog(@"loadMemePage called");
	// reset nextPageToLoad, we want a complete retry
	ourPersonalMeemi.nextPageToLoad = 1;
	ourPersonalMeemi.delegate = self;
	if(self.replyTo != nil)
		[ourPersonalMeemi getMemeRepliesOf:self.replyTo screenName:self.replyScreenName total:[self.replyQuantity intValue]];
	else 
		[ourPersonalMeemi getMemes];
}

#pragma mark MeemiDelegate

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error
{
	// if error == nil we, probably, are called because of a wrong username
	DLog(@"in WithFriendsCOnrtoller didFailWithError. Error is %@", error);
	if(error != nil)
	{
		NSString *theMessage = [NSString stringWithFormat:NSLocalizedString(@"Error loading data: %@. Please try again later", @""),
								[error localizedDescription]];
		UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
															message:theMessage
														   delegate:nil
												  cancelButtonTitle:@"OK" 
												  otherButtonTitles:nil] 
								 autorelease];
		[theAlert show];
	}
}	

-(void)meemi:(MeemiRequest)request didFinishWithResult:(MeemiResult)result
{
	// If returning from "get new replies", get avatars if needed.
	if(request == MMGetNewReplies)
	{
		DLog(@"got replies");
//		[[Meemi sharedSession] updateAvatars];
	}
	// If pvt received, call pvtSent...
	if(request == MMGetNewPvt)
		[privateFetchMeemi getMemePrivateSent];
	// if private sent, kill private Meemi session
	if(request == MMGetNewPvtSent)
	{
		privateFetchMeemi.delegate = nil;
		[privateFetchMeemi release];
		privateFetchMeemi = nil;
	}
//	[self.tableView reloadData];
}

#pragma mark ImageSenderControllerDelegate & TextSenderControllerDelegate

-(void)doneWithTextSender
{
	self.navigationController.navigationBarHidden = NO;
	[self.navigationController popViewControllerAnimated:YES];
	// reload to get new meme
	[self loadMemePage];
}

-(void)doneWithImageSender
{
	[self doneWithTextSender];
}

#pragma mark Reply and Reload

-(IBAction)replyToMeme:(id)sender
{
	DLog(@"replyToMeme: called");
	// If we are on private messages view (not reply) go on with a private message
	if(currentFetch == FTPvt)
	{
		DLog(@"Send a private meme to ourselves: %@", [Meemi screenName]);
		TextSender *controller = [[TextSender alloc] initWithNibName:@"TextSender" bundle:nil];
		controller.delegate = self;
		controller.recipientNames = [Meemi screenName];
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else
	{
		// Make user choose if (s)he wants to reply with text or image
		UIActionSheet *chooseIt = [[[UIActionSheet alloc] initWithTitle:@"Reply with?" 
															   delegate:self 
													  cancelButtonTitle:@"Cancel"
												 destructiveButtonTitle:nil
													  otherButtonTitles:@"Text", @"Image", nil]
								   autorelease];
		if(self.navigationController.toolbar.hidden)
			[chooseIt showInView:self.view];
		else // we have a toolbar, use it!
			[chooseIt showFromToolbar:self.navigationController.toolbar];
	}
}	

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSLog(@"Picked button #%d", buttonIndex);
	if(buttonIndex == 0) // Text
	{
		TextSender *controller = [[TextSender alloc] initWithNibName:@"TextSender" bundle:nil];
		controller.delegate = self;
		controller.replyTo = self.replyTo;
		controller.replyScreenName = self.replyScreenName;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
	else if(buttonIndex == 1) // Image
	{
		ImageSender *controller = [[ImageSender alloc] initWithNibName:@"ImageSender" bundle:nil];
		controller.delegate = self;
		controller.replyTo = self.replyTo;
		controller.replyScreenName = self.replyScreenName;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
}

#pragma mark Searchbar & delegate

-(void)dismissSearch
{
	self.tableView.tableHeaderView = nil;
	barPresent = NO;
	searchString = @"";
	[self setupFetch];
}

-(IBAction)searchClicked:(id)sender
{
	if(!barPresent)
	{
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] 
							  atScrollPosition:UITableViewScrollPositionTop 
									  animated:NO];
		self.tableView.tableHeaderView = self.theSearchBar;
		barPresent = YES;
		[self.theSearchBar becomeFirstResponder];
	}
	else 
	{
		[self dismissSearch];
	}
	
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	[self dismissSearch];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	DLog(@"searchBarSearchButtonClicked here");
	DLog(@"text to search: \"%@\"", searchBar.text);
	DLog(@"Scope is %d", searchBar.selectedScopeButtonIndex);
	self.searchString = searchBar.text;
	self.searchScope = searchBar.selectedScopeButtonIndex;
	[searchBar resignFirstResponder];
	[self setupFetch];
}

#pragma mark Standard Stuff

- (void)viewDidLoad 
{
    [super viewDidLoad];

	// Setup the "reload" view
	[[NSBundle mainBundle] loadNibNamed:@"headerView" owner:self options:nil];
	self.headerView.frame = CGRectMake(0.0f, -65.0f, 320.0f, 65.0f);
	self.headerView.hidden = NO;
	[self.view addSubview:self.headerView];
	self.watermark = INT_MAX;
	DLog(@"nib loaded. headerView is now: %@", self.headerView);
	
	// If no standard user push settings view
	if(![[NSUserDefaults standardUserDefaults] integerForKey:@"userValidated"])
		[self settingsView];
	
	// "Cache" the UIImages
	imgCamera = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"camera-verysmall" ofType:@"png"]];
	[imgCamera retain];
	imgVideo = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"video-verysmall" ofType:@"png"]];
	[imgVideo retain];
	imgLink= [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"link-verysmall" ofType:@"png"]];
	[imgLink retain];
	imgBlackFlag = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"BlackFlag" ofType:@"png"]];
	[imgBlackFlag retain];
	imgWhiteFlag = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"WhiteFlag" ofType:@"png"]];
	[imgWhiteFlag retain];
	imgSemplice = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"memeSemplice" ofType:@"png"]];
	[imgSemplice retain];
	imgNothing = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Nothing" ofType:@"png"]];
	[imgNothing retain];
	imgLock = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"icon-lock2.png" ofType:@"png"]];
	[imgLock retain];
	imgStar = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"star" ofType:@"png"]];
	[imgStar retain];
	
	// Setup the Meemi "agent"
	ourPersonalMeemi = [[Meemi alloc] initFromUserDefault];
	if(!ourPersonalMeemi)
		ALog(@"Meemi session init failed. Shit...");
	ourPersonalMeemi.delegate = self;
	
	self.searchString = @"";
	
	self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"fondino.png"]];
	self.tableView.backgroundColor = [UIColor clearColor];
	
#define kButtonWidth 55.0f

	if(self.replyTo == nil)
	{
		[self loadMemePage];
		
		// Add a left button for reloading the meme list
		UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"20-gear2" ofType:@"png"]] 
																		 style:UIBarButtonItemStylePlain 
																		target:self 
																		action:@selector(settingsView)];
		self.navigationItem.leftBarButtonItem = reloadButton;
		[reloadButton release];
		UIBarButtonItem *readB = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Checkmark" ofType:@"png"]] 
																  style:UIBarButtonItemStyleBordered 
																 target:((MeemiAppDelegate *)[[UIApplication sharedApplication] delegate])
																 action:@selector(markReadMemes)];
		[readB setWidth:kButtonWidth];
		UIBarButtonItem *srchB = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"magnifying-glass" ofType:@"png"]] 
																  style:UIBarButtonItemStyleBordered 
																 target:self 
																 action:@selector(searchClicked:)];
		[srchB setWidth:kButtonWidth];
		UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		NSArray *tempStrings = [NSArray arrayWithObjects:
								[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"HomeForSegmented" ofType:@"png"]],
								[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LockForSegmented" ofType:@"png"]],
								[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UserForSegmented" ofType:@"png"]]
								, nil];
		UISegmentedControl *theSegment = [[UISegmentedControl alloc] initWithItems:tempStrings];
		theSegment.segmentedControlStyle = UISegmentedControlStyleBar;
		// That's 138, 176, 218 "meemi chiaro"
		theSegment.tintColor = [UIColor colorWithRed:0.54118 green:0.6902 blue:0.8549 alpha:1.0];
		theSegment.momentary = NO;
		theSegment.selectedSegmentIndex = 0;
		for (int i = 0; i < 3; i++)
			[theSegment setWidth:kButtonWidth forSegmentAtIndex:i];
		[theSegment addTarget:self action:@selector(filterSelected) forControlEvents:UIControlEventValueChanged];
		NSArray *toolbarItems = [NSArray arrayWithObjects:
								 readB,
								 spacer,
								 [[[UIBarButtonItem alloc] initWithCustomView:theSegment] autorelease], 
								 spacer,
								 srchB,
								 nil];
		self.toolbarItems = toolbarItems;
		[theSegment release];
		[spacer release];
		[srchB release];
		[readB release];
		currentFetch = FTAll;
		[self setupFetch];
	}
	else
	{
		currentFetch = FTReplyView;
		readMemes = 0;
		self.title = NSLocalizedString(@"Thread", @"");
		[self loadMemePage];
		// Toolbar buttons
		UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		UIBarButtonItem *specialB = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"StartForSegmented" ofType:@"png"]] 
																   style:UIBarButtonItemStyleBordered 
																  target:self
																  action:@selector(doNothing:)];
		[specialB setWidth:kButtonWidth];
		UIBarButtonItem *favB = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"FavoriteButton" ofType:@"png"]] 
																  style:UIBarButtonItemStyleBordered 
																 target:self
																 action:@selector(doNothing:)];
		[favB setWidth:kButtonWidth];
		UIBarButtonItem *shareB = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ReshareButton" ofType:@"png"]] 
																  style:UIBarButtonItemStyleBordered 
																 target:self
																 action:@selector(doNothing:)];
		[shareB setWidth:kButtonWidth];
		NSArray *toolbarItems = [NSArray arrayWithObjects:specialB, spacer, favB, spacer, shareB, nil];
		self.toolbarItems = toolbarItems;
		[shareB release];
		[favB release];
		[specialB release];
		[spacer release];
	}
	// hid the search bar...
	self.tableView.tableHeaderView = nil;
	// Show the toolbar
	self.navigationController.toolbarHidden = NO;
	
	// Add a right button for reply to the meme list
	UIBarButtonItem *replyButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
																				 target:self 
																				 action:@selector(replyToMeme:)];
	self.navigationItem.rightBarButtonItem = replyButton;
	[replyButton release];
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	// Show the toolbar
	self.navigationController.toolbarHidden = NO;
	// Add notifications observers
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(meemiIsBusy:) name:kNowBusy object:nil];		
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(meemiIsFree:) name:kNowFree object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeNewData:) name:NSManagedObjectContextDidSaveNotification object:nil];
	// And register to be notified for shaking and busy/not busy of Meemi session
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceShaken:) name:@"deviceShaken" object:nil];
	if(self.replyTo == nil)
	{
		if([Meemi isBusy])
			[self meemiIsBusy:nil];
		else
			[self meemiIsFree:nil];
		// Load settings, if still needed.
		if(![Meemi isValid])
			[self settingsView];		
	}
	else // reinit fetch only for replies...
	{
//		[self loadMemePage];
		[self setupFetch];
	}
}

- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	specialThread = NO;
	[self.tableView reloadData];
}


- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	// if this is a specialThread, mark the parent "Special"
	if(specialThread && self.replyTo != nil)
		[Meemi markMemeSpecial:self.replyTo];
	// if this is the detail view, reset fetchcontroller...
	if(self.replyTo != nil && theMemeList != nil)
	{
		theMemeList.delegate = nil;
		[theMemeList release];
		theMemeList = nil;
		// and mark the thread read...
		[Meemi markThreadRead:self.replyTo];
	}
	// It happens that we don't need any callback from Meemi anymore.
	if([Meemi sharedSession].delegate == self)
		[Meemi sharedSession].delegate = nil;
	if(ourPersonalMeemi.delegate = self)
		ourPersonalMeemi.delegate = nil;
}

/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	// release the "Cache" the UIImages
	[imgCamera release];
	imgCamera = nil;
	[imgVideo release];
	imgVideo = nil;
	[imgLink release];
	imgLink = nil;
	[imgBlackFlag release];
	imgBlackFlag = nil;
	[imgWhiteFlag release];
	imgWhiteFlag = nil;
	[imgNothing release];
	imgNothing = nil;
	[imgSemplice release];
	imgSemplice = nil;
	[imgLock release];
	imgLock = nil;
	[imgStar release];
	imgStar = nil;
	// Release other...
	[self.theSearchBar release];
	self.theSearchBar = nil;
	ourPersonalMeemi.delegate = nil;
	[ourPersonalMeemi release];
	ourPersonalMeemi = nil;
	[theMemeList release];
	theMemeList = nil;
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
	[self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return [[theMemeList sections] count];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[theMemeList sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

#define kTextWidth 271.0f
#define kHeigthBesideText 85.0f
#define kExtraHeightForReload 50.0f

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *cellIdentifier;
	
	if((currentFetch == FTAll || currentFetch == FTReplyView) && indexPath.row == (self.watermark - 1))
		cellIdentifier = @"LoadAgainMemeCell";
	else
		cellIdentifier = @"MemeCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
    if (cell == nil) 
	{
		[[NSBundle mainBundle] loadNibNamed:cellIdentifier owner:self options:nil];
        cell = memeCell;
        self.memeCell = nil;
    }
    
	Meme *theFetchedMeme = [theMemeList objectAtIndexPath:indexPath];
    UILabel *tempLabel;
    tempLabel = (UILabel *)[cell viewWithTag:1];
    tempLabel.text = theFetchedMeme.screen_name;
    tempLabel = (UILabel *)[cell viewWithTag:5];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[NSLocale currentLocale]];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	if(currentFetch == FTReplyView)
		tempLabel.text = [dateFormatter stringFromDate:theFetchedMeme.date_time];
	else
		tempLabel.text = [dateFormatter stringFromDate:theFetchedMeme.dt_last_movement];
	[dateFormatter release];
	
	// avatar clickable image (this one assumes all user in section 0) screen_name is passed in transparent text.
	UIButton *tempButton = (UIButton *)[cell viewWithTag:6];
	[tempButton setBackgroundImage:[UIImage imageWithData:theFetchedMeme.user.avatar_44] forState:UIControlStateNormal];
	[tempButton setTitle:[NSString stringWithFormat: @"%lu", (unsigned long) indexPath.row] forState:UIControlStateNormal];
	
	// Reply and disclosure
	tempLabel = (UILabel *)[cell viewWithTag:4];
	if([theFetchedMeme.qta_replies intValue] == 0 || self.replyTo != nil)
	{
		// Hide also disclosure sign if simple text
		if([theFetchedMeme.meme_type isEqualToString:@"text"])
			tempLabel.text = @"";
		else
			tempLabel.text = @">";
	}
	else
		tempLabel.text = [NSString stringWithFormat:@"%@ >", theFetchedMeme.qta_replies];

	// things that depend on the kind of meme
	
	// This is the calculated size of "content"
	tempLabel = (UILabel *)[cell viewWithTag:3];
	tempLabel.text = theFetchedMeme.content;
	tempLabel.font = [UIFont systemFontOfSize:13.0f];
	tempLabel.lineBreakMode = UILineBreakModeWordWrap;
	CGRect labelFrame = tempLabel.frame;
	labelFrame.size.width = kTextWidth;
	tempLabel.frame = labelFrame;
	[tempLabel sizeToFit];
	
	UIImageView *tempView = (UIImageView *)[cell viewWithTag:7];
	if([theFetchedMeme.meme_type isEqualToString:@"image"])
		tempView.image = imgCamera;
	else if([theFetchedMeme.meme_type isEqualToString:@"video"])
		tempView.image = imgVideo;
	else if([theFetchedMeme.meme_type isEqualToString:@"link"])
		tempView.image = imgLink;
	else // should be "text" only, but who knows
		tempView.image = nil;
	
	// Set the "new"s'...
	tempView = (UIImageView *)[cell viewWithTag:8];
	if([theFetchedMeme.new_meme boolValue])
		tempView.image = imgBlackFlag;
	else if([theFetchedMeme.new_replies boolValue])
		tempView.image = imgWhiteFlag;
	else
		tempView.image = imgSemplice;
	// "Private" memes
	if([theFetchedMeme.private_meme boolValue])
	{
		((UIImageView *)[cell viewWithTag:10]).image = imgLock;
		tempLabel = (UILabel *)[cell viewWithTag:2];
		tempLabel.text = theFetchedMeme.sent_to;
	}
	else
	{
		tempLabel = (UILabel *)[cell viewWithTag:2];
		tempLabel.text = theFetchedMeme.user.real_name;
		// "Special" only if not private! Mark also state for parent marking (if needed)
		if([theFetchedMeme.special boolValue])
		{
			((UIImageView *)[cell viewWithTag:10]).image = imgStar;
			if(currentFetch == FTReplyView)
			{
				specialThread = YES;
				DLog(@"Set specialThread to YES");
			}
		}
		else
			((UIImageView *)[cell viewWithTag:10]).image = imgNothing;
	}
	
	// 11 is "reshared"
	// 12 is "favorite"
	
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	float retVal;
	Meme *theFetchedMeme = [theMemeList objectAtIndexPath:indexPath];
	if(theFetchedMeme)
	{
		CGSize theSize = [theFetchedMeme.content sizeWithFont:[UIFont systemFontOfSize:13.0f] constrainedToSize:CGSizeMake(kTextWidth, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
		retVal = theSize.height + kHeigthBesideText;
	}
	else
	{
		ALog(@"### Invalid Fetched Meme @ heightForRowAtIndexPath:%@. Watermark: %d", indexPath.row, self.watermark);
		retVal = kHeigthBesideText;
	}
	if((currentFetch == FTAll || currentFetch == FTReplyView) && indexPath.row == (self.watermark - 1))
	{
		DLog(@"heightForRowAtIndexPath set watermark st row %d", self.watermark);
		retVal += kExtraHeightForReload;
	}
	return retVal;
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//	
//}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
//{ 
//    id <NSFetchedResultsSectionInfo> sectionInfo = [[theMemeList sections] objectAtIndex:section];
//    return [sectionInfo name];
//}
//
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView 
{
    return [theMemeList sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index 
{
    return [theMemeList sectionForSectionIndexTitle:title atIndex:index];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];

	Meme *selectedMeme = ((Meme *)[theMemeList objectAtIndexPath:indexPath]);
	[Meemi markMemeRead:selectedMeme.id];
		
	// if we are at a meme list level (we need it for reply) just push another controller, same kind of this one. :)
	if(self.replyTo == nil)
	{
		WithFriendsController *controller = [[WithFriendsController alloc] initWithNibName:@"WithFriendsController" bundle:nil];
		controller.replyTo = selectedMeme.id;
		controller.replyScreenName = selectedMeme.screen_name;
		controller.replyQuantity = selectedMeme.qta_replies;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
		controller = nil;
	}
	else // This is a reply thread list OR a meme without replies (show directly if needed or do nothing if text)
	{
		// If meme is a link, simply push a browser Windows on it.
		if([selectedMeme.meme_type isEqualToString:@"link"])
		{
			MemeOnWeb *controller = [[MemeOnWeb alloc] initWithNibName:@"MemeOnWeb" bundle:nil];
			controller.urlToBeLoaded = [selectedMeme.link stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
			controller = nil;
		}
		else if([selectedMeme.meme_type isEqualToString:@"image"])
		{
			MemeOnWeb *controller = [[MemeOnWeb alloc] initWithNibName:@"MemeOnWeb" bundle:nil];
			controller.urlToBeLoaded = [selectedMeme.image_url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
			controller = nil;
		}
		else if([selectedMeme.meme_type isEqualToString:@"video"])
		{
			DLog(@"video meme: %@", selectedMeme.video);
			// Check if the URl is valid
			if([NSURL URLWithString:selectedMeme.video])
			{	// URL is valid
				MemeOnWeb *controller = [[MemeOnWeb alloc] initWithNibName:@"MemeOnWeb" bundle:nil];
				controller.urlToBeLoaded = [selectedMeme.video stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				[self.navigationController pushViewController:controller animated:YES];
				[controller release];
				controller = nil;
			}
			else
			{
				// tell user that the video cannot be shown
				UIAlertView *theAlert = [[[UIAlertView alloc] initWithTitle:@"Error"
																	message:@"This video cannot be shown on this device"
																   delegate:nil
														  cancelButtonTitle:@"OK" 
														  otherButtonTitles:nil] 
										 autorelease];
				[theAlert show];
			}
		}
		else 
		{
			// try to decode the content to see if an URL is present.
			NSString *urlRegex = @"\\bhttps?://[a-zA-Z0-9\\-.]+(?:(?:/[a-zA-Z0-9\\-._?,'+\\&%$=~*!():@\\\\]*)+)?";	
			if([selectedMeme.content isMatchedByRegex:urlRegex])
			{
				NSArray *matchedURLsArray = [selectedMeme.content componentsMatchedByRegex:urlRegex];
				DLog(@"matchedURLsArray: %@", matchedURLsArray);
				MemeOnWeb *controller = [[MemeOnWeb alloc] initWithNibName:@"MemeOnWeb" bundle:nil];
				controller.urlToBeLoaded = [[matchedURLsArray objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				[self.navigationController pushViewController:controller animated:YES];
				[controller release];
				controller = nil;					
			}
			
		}

	}
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark Scrolling Overrides


// Labels: ☝☟

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	if([self.laRuota isAnimating])
		checkForRefresh = NO;
	else
	{
		checkForRefresh = YES;  //  only check offset when dragging
		enoughDragging = NO;
	}
} 

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (checkForRefresh) 
	{
		if(scrollView.contentOffset.y >= 0.0f)
			return;

		if(!enoughDragging && scrollView.contentOffset.y < -65.0f)
		{
			self.headerLabel.text = NSLocalizedString(@"Release to Reload", @"");
			self.headerArrow.text = @"☝";
			enoughDragging = YES;
		}
		if(enoughDragging && scrollView.contentOffset.y > -65.0f)
		{
			self.headerLabel.text = NSLocalizedString(@"Pull down to Reload", @"");
			self.headerArrow.text = @"☟";
			enoughDragging = NO;
		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
				  willDecelerate:(BOOL)decelerate
{
	DLog(@"Scrolldrag end");
	enoughDragging = NO;
	checkForRefresh = NO;	
	if (scrollView.contentOffset.y <= - 65.0f) 
	{
		// start reloading, and reset controls...
		self.headerLabel.text = NSLocalizedString(@"Reloading...", @"");
		self.headerArrow.text = @" ";
		[self.laRuota startAnimating];
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2];
		self.tableView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f, 0.0f);
		[UIView commitAnimations];			
		[self loadMemePage];
	}
}


- (void)dealloc {
    [super dealloc];
}


@end

