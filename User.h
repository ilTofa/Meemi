//
//  User.h
//  Meemi
//
//  Created by Giacomo Tufano on 02/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <CoreData/CoreData.h>

@class Avatar;
@class Meme;

@interface User :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSDate * since;
@property (nonatomic, retain) NSDate * birth;
@property (nonatomic, retain) NSString * real_name;
@property (nonatomic, retain) NSString * screen_name;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) Avatar * avatar;
@property (nonatomic, retain) NSSet* meme;

@end


@interface User (CoreDataGeneratedAccessors)
- (void)addMemeObject:(Meme *)value;
- (void)removeMemeObject:(Meme *)value;
- (void)addMeme:(NSSet *)value;
- (void)removeMeme:(NSSet *)value;

@end

