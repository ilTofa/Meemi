//
//  UserDetail.m
//  Meemi
//
//  Created by Giacomo Tufano on 09/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "UserDetail.h"
#import "User.h"
#import "UserProfile.h"

#import "GANTracker.h"

@implementation UserDetail


#pragma mark -
#pragma mark View lifecycle

- (void)reloadAvatars
{
	if(!reloadInProgress)
	{
		NSError *error;
		DLog(@"starting avatar update");
		reloadInProgress = YES;
		[ourPersonalMeemi allAvatarsReload];
		[[GANTracker sharedTracker] trackPageview:@"/avatarsReloaded" withError:&error];
	}
	else 
	{
		DLog(@"reloadAvatars still in progress. Request ignored.");
	}

}

#pragma mark MeemiDelegate

-(void)meemi:(MeemiRequest)request didFailWithError:(NSError *)error
{
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
	DLog(@"Avatar update terminated *with errors*");
	reloadInProgress = NO;
}

-(void)meemi:(MeemiRequest)request didFinishWithResult:(MeemiResult)result
{
	DLog(@"Avatar update terminated");
	reloadInProgress = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

	self.title = @"Meemers";
	self.parentViewController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"fondino.png"]];
	self.tableView.backgroundColor = [UIColor clearColor];	
	
	NSManagedObjectContext *context = [Meemi managedObjectContext];
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Configure the request's entity, and optionally its predicate.
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
	[fetchRequest setEntity:entityDescription];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"screen_name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor release];
	
	theUserList = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest 
													  managedObjectContext:context 
														sectionNameKeyPath:nil 
																 cacheName:@"UserDetailCache"];
	[fetchRequest release];
	theUserList.delegate = self;
	
	NSError *error;
	if(![theUserList performFetch:&error])
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
	UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
																				  target:self 
																				  action:@selector(reloadAvatars)];
	self.navigationItem.rightBarButtonItem = reloadButton;
	[reloadButton release];

	// Setup the Meemi "agent"
	ourPersonalMeemi = [[Meemi alloc] initFromUserDefault];
	if(!ourPersonalMeemi)
		ALog(@"Meemi session init failed. Shit...");
	ourPersonalMeemi.delegate = self;
	reloadInProgress = NO;
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
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

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller 
{
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    NSUInteger count = [[theUserList sections] count];
	// "Official" workaround for problem in iPhone OS 3
    if (count == 0) 
        count = 1;
    return count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
 	// "Official" workaround for problem in iPhone OS 3
	NSArray *sections = [theUserList sections];
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
    
    static NSString *CellIdentifier = @"UserListCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    User *theFetchedUser = [theUserList objectAtIndexPath:indexPath];

	UIImage *tempImage = [[UIImage alloc] initWithCGImage:[[UIImage imageWithData:theFetchedUser.avatar_44] CGImage] 
													scale:[[UIScreen mainScreen] scale]
											  orientation:UIImageOrientationUp];
    cell.imageView.image = tempImage;
	[tempImage release];
	cell.textLabel.text = theFetchedUser.screen_name;
	cell.detailTextLabel.text = theFetchedUser.real_name;
    
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView 
{
    return [theUserList sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index 
{
    return [theUserList sectionForSectionIndexTitle:title atIndex:index];
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


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // Navigation logic may go here. Create and push another view controller.
	
	UserProfile *detailViewController = [[UserProfile alloc] initWithNibName:@"UserProfile" bundle:nil];
	detailViewController.theUser = [theUserList objectAtIndexPath:indexPath];
	// Pass the selected object to the new view controller.
	[self.navigationController pushViewController:detailViewController animated:YES];
	NSError *error;
	[[GANTracker sharedTracker] trackPageview:@"/userFromList" withError:&error];
	[detailViewController release];	
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	ALog(@"[UserDetail viewDidUnload] called");
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
	theUserList.delegate = nil;
	[theUserList release];
	theUserList = nil;
	
	ourPersonalMeemi.delegate = nil;
	[ourPersonalMeemi release];
	ourPersonalMeemi = nil;
}


- (void)dealloc 
{
    [super dealloc];
	if(theUserList)
		theUserList.delegate = nil;
}


@end

