//
//  SPSchema.m
//  Simperium
//
//  Created by Michael Johnston on 11-05-16.
//  Copyright 2011 Simperium. All rights reserved.
//

#import "Simperium.h"
#import "SPSchema.h"
#import "SPMember.h"
#import "SPMemberText.h"
#import "SPMemberDate.h"
#import "SPMemberInt.h"
#import "SPMemberFloat.h"
#import "SPMemberDouble.h"
#import "SPMemberEntity.h"
#import "SPMemberList.h"
#import "SPMemberBase64.h"
#import "SPMemberBinary.h"

@implementation SPSchema
@synthesize bucketName;
@synthesize members;
@synthesize binaryMembers;
@synthesize dynamic;

// Maps primitive type strings to base member classes
-(Class)memberClassForType:(NSString *)type
{
	if ([type isEqualToString:@"text"])
		return [SPMemberText class];
	else if ([type isEqualToString:@"int"] || [type isEqualToString:@"bool"])
		return [SPMemberInt class];
	else if ([type isEqualToString:@"date"])
		return [SPMemberDate class];
    else if ([type isEqualToString:@"entity"])
        return [SPMemberEntity class];
    else if ([type isEqualToString:@"double"])
        return [SPMemberDouble class];
    else if ([type isEqualToString:@"binary"])
        return [SPMemberBinary class];
    else if ([type isEqualToString:@"list"])
        return [SPMemberList class];
    else if ([type isEqualToString:@"base64"])
        return [SPMemberBase64 class];
	
	// error
	return nil;
}

// Loads an entity's definition (name, members, their types, etc.) from a plist dictionary
-(id)initWithBucketName:(NSString *)name data:(NSDictionary *)definition
{
    if (self = [super init]) {
        bucketName = [name copy];
        NSArray *memberList = [definition valueForKey:@"members"];
        members = [[NSMutableArray arrayWithCapacity:3] retain];
        binaryMembers = [[NSMutableArray arrayWithCapacity:3] retain];
        for (NSDictionary *memberDict in memberList) {
            NSString *typeStr = [memberDict valueForKey:@"type"];
            SPMember *member = [[[self memberClassForType:typeStr] alloc] initFromDictionary:memberDict];
            [members addObject: member];
            
            if ([member isKindOfClass:[SPMemberBinary class]])
                [binaryMembers addObject: member];
            [member release];
        }        
    }
    
    return self;
}

-(void)dealloc {
    [members release];
    [binaryMembers release];
    [super dealloc];
}

-(NSString *)bucketName {
	return bucketName;
}

-(void)addMemberForObject:(id)object key:(NSString *)key {
    if (!dynamic)
        return;
    
    // Make this faster via dictionary lookup
    if ([self memberNamed:key])
        return;
    
    NSString *type = @"unsupported";
    if ([object isKindOfClass:[NSString class]])
        type = @"text";
    else if ([object isKindOfClass:[NSNumber class]])
        type = @"double";
    
    NSDictionary *memberDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                type, @"type",
                                key, @"name", nil];
    SPMember *member = [[[self memberClassForType:type] alloc] initFromDictionary:memberDict];
    [members addObject:member];
    [member release];
    
}

-(SPMember *)memberNamed:(NSString *)memberName {
	// Would be more efficient to use NSSet?
	for (SPMember *member in self.members) {
		if ([[member keyName] compare: memberName] == NSOrderedSame)
			return member;
	}		
	return nil;
}

-(void)setDefaults:(id<SPDiffable>)object
{
    // Set default values for all members that don't already have them
    // This now gets called after some data might already have been set, so be careful
    // not to overwrite it
    for (SPMember *member in members) {
        if (member.modelDefaultValue == nil && [object simperiumValueForKey:member.keyName] == nil)
            [object simperiumSetValue:[member defaultValue] forKey:member.keyName];
    }
}

@end
