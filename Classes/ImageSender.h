//
//  ImageSender.h
//  Meemi
//
//  Created by Giacomo Tufano on 20/03/10.
//  Copyright 2010 Giacomo Tufano (gt@ilTofa.it). All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ImageSender : UIViewController 
{
	UITextField *description;
	UIImageView *theImageView;
	UIImage *theImage;
	UIActivityIndicatorView *laRuota;
}

@property (retain, nonatomic) IBOutlet UITextField *description;
@property (retain, nonatomic) IBOutlet UIImageView *theImageView;
@property (retain, nonatomic) IBOutlet UIImage *theImage;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *laRuota;

-(IBAction)sendIt:(id)sender;
-(IBAction)cancel:(id)sender;

@end
