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

@implementation Signature
- (NSString*)description
{
    return [NSString stringWithFormat:@"%.2x %.2x %.2x", self->s1, self->s2, self->s3];
}

- (BOOL)isEqual: (id)other
{
    return [self hash] == [other hash];
}

- (NSUInteger)hash
{
    return (self->s1 << 16) + (self->s2 << 8) + self->s3;
}


-(id)copyWithZone:(NSZone*)zone
{
    Signature *newSignature = [[[self class] allocWithZone:zone] init];
    newSignature->s1 = self->s1;
    newSignature->s2 = self->s2;
    newSignature->s3 = self->s3;
    return newSignature;
}
@end
