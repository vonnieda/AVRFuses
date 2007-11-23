//
//  PartDefinition.h
//  AVRFuses
//
//  Created by Jason von Nieda on 11/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PartDefinition : NSObject 
{
	@public
	NSString *name;
	NSMutableDictionary *fuses;
}

-(id)init;
@end

@interface FuseDefinition : NSObject
{
	@public
	NSString *name;
	NSMutableArray *settings;
}
@end

@interface FuseSetting: NSObject
{
	@public
	NSString *fuse;
	unsigned char mask;
	unsigned char value;
	NSString *text;
}
@end
