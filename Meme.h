//
//  Meme.h
//  Meemi
//
//  Created by Giacomo Tufano on 20/04/10.
//  Copyright 2010 Sun Microsystems Italia SpA. All rights reserved.
//

#import <CoreData/CoreData.h>

@class User;

@interface Meme :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * qta_replies;
@property (nonatomic, retain) NSString * location;
@property (nonatomic, retain) NSString * posted_from;
@property (nonatomic, retain) NSDate * dt_last_movement;
@property (nonatomic, retain) NSString * link;
@property (nonatomic, retain) NSString * image_medium;
@property (nonatomic, retain) NSDate * event_when;
@property (nonatomic, retain) NSString * event_name;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * image_medium_url;
@property (nonatomic, retain) NSData * image_small;
@property (nonatomic, retain) NSString * image_url;
@property (nonatomic, retain) NSString * event_where;
@property (nonatomic, retain) NSString * reply_screen_name;
@property (nonatomic, retain) NSString * quote_source;
@property (nonatomic, retain) NSString * image_small_url;
@property (nonatomic, retain) NSString * screen_name;
@property (nonatomic, retain) NSDate * date_time;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSNumber * new_meme;
@property (nonatomic, retain) NSNumber * reply_id;
@property (nonatomic, retain) NSString * channels;
@property (nonatomic, retain) NSString * meme_type;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSNumber * new_replies;
@property (nonatomic, retain) User * user;

@end



