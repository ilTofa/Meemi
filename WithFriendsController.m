//
//  WithFriendsController.m
//  Meemi
//
//  Created by Giacomo Tufano on 02/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "WithFriendsController.h"
#import "Meme.h"
#import "MemeOnWeb.h"

@implementation WithFriendsController

@synthesize memeCell, predicateString, searchString;

-(void)deviceShaken:(NSNotification *)note
{
	DLog(@"SHAKED!");
	// If session is not busy, reload.
	if(![Meemi sharedSession].isBusy)
		[(MeemiAppDelegate *)[[UIApplication sharedApplication] delegate] reloadMemes];
}

-(void)meemiIsBusy:(NSNotification *)note
{
	DLog(@"meemiIsBusy: dimming navButtons");
	self.navigationItem.rightBarButtonItem.enabled = self.navigationItem.leftBarButtonItem.enabled = NO;
}

-(void)meemiIsFree:(NSNotification *)note
{
	DLog(@"meemiIsFree: enabling navButtons");
	self.navigationItem.rightBarButtonItem.enabled = self.navigationItem.leftBarButtonItem.enabled = YES;
	// While we are at it, probably the session something should have read. :)
	[self.tableView reloadData];
}

-(void)setupFetch
{
	NSManagedObjectContext *context = [Meemi sharedSession].managedObjectContext;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Configure the request's entity, and optionally its predicate.
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Meme" inManagedObjectContext:context];
	[fetchRequest setEntity:entityDescription];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dt_last_movement" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	switch(currentFetch)
	{
		case FTAll:
			if([self.searchString isEqualToString:@""])
				self.predicateString = @"";
			else
				self.predicateString = [NSString stringWithFormat:@"screen_name like %@", self.searchString];
			break;
		case FTNew:
			if([self.searchString isEqualToString:@""])
				self.predicateString = [NSString stringWithFormat:@"new_meme == %@ OR new_replies == %@", 
										[NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES]];
			else
				self.predicateString = [NSString stringWithFormat:@"screen_name like %@ AND (new_meme == %@ OR new_replies == %@)",
										self.searchString,
										[NSNumber numberWithBool:YES], [NSNumber numberWithBool:YES]];
			break;
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
		[theMemeList release];
	theMemeList = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
													  managedObjectContext:context 
														sectionNameKeyPath:nil 
																 cacheName:@"WithFriendsCache"];
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
}	

-(void)filterSelected
{
	currentFetch = ((UISegmentedControl *) (((UIBarButtonItem *)[self.toolbarItems objectAtIndex:1]).customView)).selectedSegmentIndex;
	DLog(@"in filterSelected for %d selected, filtering on '%@'", currentFetch, self.searchString);
	[self setupFetch];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];

	// Add a left button for reloading the meme list
	UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"02-redo" ofType:@"png"]] 
																	 style:UIBarButtonItemStylePlain 
																	target:((MeemiAppDelegate *)[[UIApplication sharedApplication] delegate]) 
																	action:@selector(reloadMemes)];
	
	self.navigationItem.leftBarButtonItem = reloadButton;
	[reloadButton release];
	
	UIBarButtonItem *markReadButton = [[UIBarButtonItem alloc] initWithTitle:@"Mark Read" 
																	   style:UIBarButtonItemStylePlain 
																	  target:((MeemiAppDelegate *)[[UIApplication sharedApplication] delegate]) 
																	  action:@selector(markReadMemes)];
	self.navigationItem.rightBarButtonItem  = markReadButton;
	[markReadButton release];
	
	NSArray *tempStrings = [NSArray arrayWithObjects:@"All", @"New", @"Private", @"Mentions", nil];
	UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UISegmentedControl *theSegment = [[UISegmentedControl alloc] initWithItems:tempStrings];
	theSegment.segmentedControlStyle = UISegmentedControlStyleBar;
	theSegment.tintColor = [UIColor darkGrayColor];
	theSegment.momentary = NO;
	theSegment.selectedSegmentIndex = 0;
	currentFetch = FTAll;
	[theSegment setEnabled:NO forSegmentAtIndex:2];
	[theSegment setEnabled:NO forSegmentAtIndex:3];
	[theSegment addTarget:self action:@selector(filterSelected) forControlEvents:UIControlEventValueChanged];
	NSArray *toolbarItems = [NSArray arrayWithObjects:
							 spacer,
							 [[UIBarButtonItem alloc] initWithCustomView:theSegment], spacer, nil];
	self.toolbarItems = toolbarItems;
	[theSegment release];
	[spacer release];
	self.navigationController.toolbar.barStyle = UIBarStyleBlack;
	self.navigationController.toolbarHidden = NO;

	self.searchString = @"";
	[self setupFetch];
}

- (void)viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
	// And register to be notified for shaking and busy/not busy of Meemi session
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceShaken:) name:@"deviceShaken" object:nil];
	if([Meemi sharedSession].isBusy)
		[self meemiIsBusy:nil];
	else
		[self meemiIsFree:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(meemiIsBusy:) name:kNowBusy object:nil];		
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(meemiIsFree:) name:kNowFree object:nil];
}


- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	[self.tableView reloadData];
}


- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	[theMemeList release];
}

#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	if([searchBar isFirstResponder])
		[searchBar resignFirstResponder];
	DLog(@"searchBarSearchButtonClicked");
	DLog(@"should we search for <%@>", searchBar.text);
	self.searchString = searchBar.text;
	[self setupFetch];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	DLog(@"searchBarCancelButtonClicked");
	if([searchBar isFirstResponder])
		[searchBar resignFirstResponder];
	searchBar.text = @"";
	self.searchString = searchBar.text;
	[self setupFetch];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	// Start editing only if we could reload
	return self.navigationItem.leftBarButtonItem.enabled;
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
	[self.tableView reloadData];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    NSUInteger count = [[theMemeList sections] count];
	// "Official" workaround for problem in iPhone OS 3
    if (count == 0) 
        count = 1;
    return count;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
 	// "Official" workaround for problem in iPhone OS 3
	NSArray *sections = [theMemeList sections];
    NSUInteger count = 0;
    if ([sections count]) 
	{
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        count = [sectionInfo numberOfObjects];
    }
    return count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"MemeCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
	{
		[[NSBundle mainBundle] loadNibNamed:@"MemeCell" owner:self options:nil];
        cell = memeCell;
        self.memeCell = nil;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		// This is 172/209/245 the Meemi "formal" background
//		cell.contentView.backgroundColor = [UIColor colorWithRed:0.67188 green:0.81641 blue:0.95703 alpha:1.0];
//		cell.accessoryView.backgroundColor = [UIColor colorWithRed:0.67188 green:0.81641 blue:0.95703 alpha:1.0];
    }
    Meme *theFetchedMeme = [theMemeList objectAtIndexPath:indexPath];
    UILabel *tempLabel;
    tempLabel = (UILabel *)[cell viewWithTag:1];
    tempLabel.text = theFetchedMeme.screen_name;
    tempLabel = (UILabel *)[cell viewWithTag:2];
    tempLabel.text = theFetchedMeme.user.real_name;
    tempLabel = (UILabel *)[cell viewWithTag:4];
    tempLabel.text = [NSString stringWithFormat:@"%@", theFetchedMeme.qta_replies];
    tempLabel = (UILabel *)[cell viewWithTag:5];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setLocale:[NSLocale currentLocale]];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    tempLabel.text = [dateFormatter stringFromDate:theFetchedMeme.date_time];
	[dateFormatter release];
	UIImageView *tempView = (UIImageView *)[cell viewWithTag:6];
	tempView.image = [UIImage imageWithData:theFetchedMeme.user.avatar.small];
	// things that depend on the kind of meme
	tempLabel = (UILabel *)[cell viewWithTag:3];
	tempLabel.text = theFetchedMeme.content;
	tempView = (UIImageView *)[cell viewWithTag:7];
	if([theFetchedMeme.meme_type isEqualToString:@"image"])
		tempView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"camera-verysmall" ofType:@"png"]];
	else if([theFetchedMeme.meme_type isEqualToString:@"video"])
		tempView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"video-verysmall" ofType:@"png"]];
	else if([theFetchedMeme.meme_type isEqualToString:@"link"])
		tempView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"link-verysmall" ofType:@"png"]];
	else // should be "text" only, but who knows
		tempView.image = nil;
	// Hide the "new" flags if meme is not new...
	if([theFetchedMeme.new_meme boolValue])
		((UIImageView *)[cell viewWithTag:8]).hidden = NO;
	else
		((UIImageView *)[cell viewWithTag:8]).hidden = YES;
	if([theFetchedMeme.new_replies boolValue])
		((UIImageView *)[cell viewWithTag:9]).hidden = NO;
	else
		((UIImageView *)[cell viewWithTag:9]).hidden = YES;
	
    return cell;
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
	Meme *selectedMeme = ((Meme *)[theMemeList objectAtIndexPath:indexPath]);
	MemeOnWeb *controller = [[MemeOnWeb alloc] initWithNibName:@"MemeOnWeb" bundle:nil];
	controller.replyTo = selectedMeme.id;
	controller.replyScreenName = selectedMeme.screen_name;
	controller.urlToBeLoaded = [NSString stringWithFormat:@"http://meemi.com/m/%@/%@", controller.replyScreenName, controller.replyTo];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
	// Mark it read, btw...
	[[Meemi sharedSession] markMemeRead:selectedMeme.id];
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


- (void)dealloc {
    [super dealloc];
}


@end

