//
//  PartDefinition.h
//  AVRFuses
//
//  Created by Jason von Nieda on 11/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FuseDefinition;

@interface PartDefinition : NSObject 
{
	@public
	NSString *name;
	NSMutableDictionary *fuses;
	FuseDefinition *lockbits;
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

@interface Signature : NSObject <NSCopying>
{
    @public
    unsigned int s1;
    unsigned int s2;
    unsigned int s3;
}
- (NSString*)description;
- (BOOL)isEqual: (id)other;
- (NSUInteger)hash;
-(id)copyWithZone:(NSZone*)zone;
@end
