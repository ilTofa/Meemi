//
//  User.h
//  Meemi
//
//  Created by Giacomo Tufano on 06/05/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <CoreData/CoreData.h>

@class Meme;

@interface User :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * screen_name;
@property (nonatomic, retain) NSString * real_name;
@property (nonatomic, retain) NSString * profile;
@property (nonatomic, retain) NSDate * birth;
@property (nonatomic, retain) NSData * avatar_medium;
@property (nonatomic, retain) NSData * avatar_original;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSDate * since;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSData * avatar_small;
@property (nonatomic, retain) NSSet* meme;

@end


@interface User (CoreDataGeneratedAccessors)
- (void)addMemeObject:(Meme *)value;
- (void)removeMemeObject:(Meme *)value;
- (void)addMeme:(NSSet *)value;
- (void)removeMeme:(NSSet *)value;

@end

