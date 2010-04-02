//
//  WithFriendsController.m
//  Meemi
//
//  Created by Giacomo Tufano on 02/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import "WithFriendsController.h"
#import "Meme.h"

@implementation WithFriendsController

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)viewDidLoad 
{
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	NSManagedObjectContext *context = [Meemi sharedSession].managedObjectContext;
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	// Configure the request's entity, and optionally its predicate.
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Meme" inManagedObjectContext:context];
	[fetchRequest setEntity:entityDescription];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor release];
	
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
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    Meme *theFetchedMeme = [theMemeList objectAtIndexPath:indexPath];
    // TODO: configure the cell with data from the managed object.
	cell.textLabel.text = theFetchedMeme.screen_name;
	cell.detailTextLabel.text = theFetchedMeme.content;
	
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{ 
    id <NSFetchedResultsSectionInfo> sectionInfo = [[theMemeList sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView 
{
    return [theMemeList sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index 
{
    return [theMemeList sectionForSectionIndexTitle:title atIndex:index];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
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

