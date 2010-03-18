//
//  Meemi.h
//  Meemi
//
//  Created by Giacomo Tufano on 18/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Meemi : NSObject 
{
	BOOL valid;
	NSString *screenName, *password;
}

@property (nonatomic, getter=isValid) BOOL valid;
@property (nonatomic, copy) NSString *screenName;
@property (nonatomic, copy) NSString *password;

+(Meemi *)sharedInstance;

-(BOOL)validateUser:(NSString *) meemi_id usingPassword:(NSString *)pwd;

@end
