//
//  Meme.h
//  Meemi
//
//  Created by Giacomo Tufano on 01/04/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Meme :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * avatar_small;
@property (nonatomic, retain) NSString * chans;
@property (nonatomic, retain) NSNumber * reply_id;
@property (nonatomic, retain) NSString * reply_screen_name;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * source;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSNumber * qta_replies;
@property (nonatomic, retain) NSNumber * favourite;
@property (nonatomic, retain) NSString * original_link;
@property (nonatomic, retain) NSDate * date_time;
@property (nonatomic, retain) NSString * screen_name;
@property (nonatomic, retain) NSString * content;

@end



