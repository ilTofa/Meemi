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

@synthesize memeCell;

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

-(IBAction)reloadMemes
{
	// Protect ourselves against more reloads...
	self.navigationItem.leftBarButtonItem.enabled = NO;

	[Meemi sharedSession].delegate = self;
	[[Meemi sharedSession] getNewMemes:YES];	
}

-(void)setupFetch:(NSString *)filterString
{
	NSManagedObjectContext *context = [Meemi sharedSession].managedObjectContext;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Configure the request's entity, and optionally its predicate.
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Meme" inManagedObjectContext:context];
	[fetchRequest setEntity:entityDescription];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:NO];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	if(![filterString isEqualToString:@""])
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"screen_name like %@", filterString];
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

- (void)viewDidLoad 
{
    [super viewDidLoad];

	// Add a left button for reloading the meme list
	UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"02-redo" ofType:@"png"]] 
																	 style:UIBarButtonItemStylePlain 
																	target:self 
																	action:@selector(reloadMemes)];
	
	self.navigationItem.leftBarButtonItem = reloadButton;
	[reloadButton release];
	
	[self setupFetch:@""];
	
	// now, load the new memes... ;)
	[self reloadMemes];
}


/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/

- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
	[self.tableView reloadData];
}

/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
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

#pragma mark MeemiDelegate

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error
{
	NSLog(@"(MeemiRequest)request didFailWithError:");
}

-(void)meemi:(MeemiRequest)request didFinishWithResult:(MeemiResult)result
{
	NSLog(@"(MeemiRequest)request didFinishWithResult:");
	switch (request) 
	{
		case MmGetNew:
			// Continue to read new memes up to "rowNumber" / 10 of them
			if(result > 20 && (result - 20) <= ([[NSUserDefaults standardUserDefaults] integerForKey:@"rowNumber"] / 10))
			{
				NSLog(@"Still records to be read, now at page %d", result - 20);
				[[Meemi sharedSession] getNewMemes:NO];
			}
			else
			{
				NSLog(@"No other records to read or max number reached, should be marking all read...");
//				[[Meemi sharedSession] markNewMemesRead];
				// Now get newUsers into db.
				[[Meemi sharedSession] getNewUsers];
			}
			break;
		case MmMarkNewRead:
			NSLog(@"New memes marked read.");
			break;
		case MmGetNewUsers:
			NSLog(@"New users and avatars updated");
			[self.tableView reloadData];
			self.navigationItem.leftBarButtonItem.enabled = YES;
			break;
		default:
			NSAssert(YES, @"(MeemiRequest)request didFinishWithResult: in WithFriendsController.m called with unknow request");
			break;
	}
}

#pragma mark UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	if([searchBar isFirstResponder])
		[searchBar resignFirstResponder];
	DLog(@"searchBarSearchButtonClicked");
	DLog(@"should we search for <%@>", searchBar.text);
	[self setupFetch:searchBar.text];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	DLog(@"searchBarCancelButtonClicked");
	if([searchBar isFirstResponder])
		[searchBar resignFirstResponder];
	searchBar.text = @"";
	[self setupFetch:searchBar.text];
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
	if([theFetchedMeme.type isEqualToString:@"image"])
		tempView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"camera-verysmall" ofType:@"png"]];
	else if([theFetchedMeme.type isEqualToString:@"video"])
		tempView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"video-verysmall" ofType:@"png"]];
	else if([theFetchedMeme.type isEqualToString:@"link"])
		tempView.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"link-verysmall" ofType:@"png"]];
	else // should be "text" only, but who knows
		tempView.image = nil;
	
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
	NSString *originalLink = ((Meme *)[theMemeList objectAtIndexPath:indexPath]).original_link;
	NSString *mobileLink = [NSString stringWithFormat:@"http://meemi.com/m/%@", [originalLink substringFromIndex:17]];
	MemeOnWeb *controller = [[MemeOnWeb alloc] initWithNibName:@"MemeOnWeb" bundle:nil];
	controller.urlToBeLoaded = mobileLink;
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
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

