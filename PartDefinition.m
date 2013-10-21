//
//  PartDefinition.m
//  AVRFuses
//
//  Created by Jason von Nieda on 11/16/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PartDefinition.h"


@implementation PartDefinition
-(id)init;
{
	self = [super init];
	fuses = [[NSMutableDictionary alloc] init];
	return self;
}
@end

@implementation FuseDefinition
-(id)init;
{
	self = [super init];
	settings = [[NSMutableArray alloc] init];
	return self;
}
@end

@implementation FuseSetting
@end
