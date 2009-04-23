//
//  main.m
//  AVRFuses
//
//  Created by Jason von Nieda on 1/29/07.
//  Copyright __MyCompanyName__ 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	// By setting this here we are able to bypass Sparkle's initial "Do you want to check?" dialog
	// and set the default to true. The user can then change it as they please.
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NSUserDefaults standardUserDefaults] registerDefaults:
		[[[NSBundle mainBundle] infoDictionary] objectForKey: @"RegistrationDefaults"]];
	[pool release];
    return NSApplicationMain(argc,  (const char **) argv);
}
