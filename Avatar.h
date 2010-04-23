//
//  Avatar.h
//  Meemi
//
//  Created by Giacomo Tufano on 23/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <CoreData/CoreData.h>

@class User;

@interface Avatar :  NSManagedObject  
{
}

@property (nonatomic, retain) NSData * original;
@property (nonatomic, retain) NSData * medium;
@property (nonatomic, retain) NSData * small;
@property (nonatomic, retain) User * user;

@end



