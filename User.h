//
//  User.h
//  Meemi
//
//  Created by Giacomo Tufano on 04/06/10.
//
//  Copyright 2011, Giacomo Tufano (gt@ilTofa.it)
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <CoreData/CoreData.h>

@class Meme;

@interface User :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDecimalNumber * qta_followers;
@property (nonatomic, retain) NSString * real_name;
@property (nonatomic, retain) NSString * profile;
@property (nonatomic, retain) NSNumber * you_follow;
@property (nonatomic, retain) NSDecimalNumber * qta_followings;
@property (nonatomic, retain) NSString * current_location;
@property (nonatomic, retain) NSString * avatar_url;
@property (nonatomic, retain) NSDate * birth;
@property (nonatomic, retain) NSNumber * follow_you;
@property (nonatomic, retain) NSData * avatar;
@property (nonatomic, retain) NSData * avatar_44;
@property (nonatomic, retain) NSDate * since;
@property (nonatomic, retain) NSString * info;
@property (nonatomic, retain) NSString * screen_name;
@property (nonatomic, retain) NSSet* meme;

@end


@interface User (CoreDataGeneratedAccessors)
- (void)addMemeObject:(Meme *)value;
- (void)removeMemeObject:(Meme *)value;
- (void)addMeme:(NSSet *)value;
- (void)removeMeme:(NSSet *)value;

@end

