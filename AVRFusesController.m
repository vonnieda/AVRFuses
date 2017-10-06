#import "AVRFusesController.h"

#import <termios.h>

#import <CoreFoundation/CoreFoundation.h>

#import <IOKit/IOKitLib.h>
#import <IOKit/serial/IOSerialKeys.h>
#import <IOKit/IOBSD.h>

/*
Need to come up with just a few  generic methods:
readMemory, verifyMemory, programMemory and use it similar to how avrdude uses -U
*/

/*
TODO removed lockbits for now so I can release 1.4
This method of reading in the configs causes problems in all the other
methods (mainly read) because of the loop that looks at all fusenames
and expects a file. I don't like having to hardcode the fuse names in each
function.

Also, right now it's fine cause we never add lockbits fusename to fuses, but if we do (like
I originally intended) then everything that uses the fuses array needs to change. Should store lockbits
seperately or come up with a more generic method of read/writing/verifying/displaying memory.
*/

@implementation AVRFusesController

- (void)awakeFromNib
{
	parts = [[NSMutableDictionary alloc] init];
    signatures = [[NSMutableDictionary alloc] init];
	selectedPart = nil;
	fuses = [[NSMutableDictionary alloc] init];
	fuseSettings = [[NSMutableArray alloc] init];
	lockbitSettings = [[NSMutableArray alloc] init];

	[fusesTableView setDoubleAction: @selector(tableViewDoubleClick:)];
	[lockbitsTableView setDoubleAction: @selector(tableViewDoubleClick:)];
	
	[self loadPartDefinitions];
    [self loadSignaturesDefinitions];

	NSArray *sortedPartNames = [[parts allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	for (int i = 0; i < [sortedPartNames count]; i++) {
		NSString *partName = [sortedPartNames objectAtIndex: i];
		[devicePopUpButton addItemWithTitle: partName];
        [projectDevicePopUpButton addItemWithTitle: partName];
	}
	
	if ([[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedPart"] != nil) {
		[devicePopUpButton selectItemWithTitle: [[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedPart"]];
	}
	
	[avrdudeSerialBaudPopUpButton removeAllItems];
	[avrdudeSerialBaudPopUpButton addItemWithTitle: @"[Default]"];
	[avrdudeSerialBaudPopUpButton addItemWithTitle: @"300"];
	[avrdudeSerialBaudPopUpButton addItemWithTitle: @"1200"];
	[avrdudeSerialBaudPopUpButton addItemWithTitle: @"2400"];
	[avrdudeSerialBaudPopUpButton addItemWithTitle: @"4800"];
	[avrdudeSerialBaudPopUpButton addItemWithTitle: @"9600"];
	[avrdudeSerialBaudPopUpButton addItemWithTitle: @"19200"];
	[avrdudeSerialBaudPopUpButton addItemWithTitle: @"38400"];
	[avrdudeSerialBaudPopUpButton addItemWithTitle: @"57600"];
	[avrdudeSerialBaudPopUpButton addItemWithTitle: @"115200"];
	
	if ([[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudeSerialBaud"] != nil) {
		[avrdudeSerialBaudPopUpButton selectItemWithTitle: [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudeSerialBaud"]];
	}
	
	[avrdudePortPopUpButton removeAllItems];
	[avrdudePortPopUpButton addItemWithObjectValue: @"usb"];
	NSMutableArray *serialPorts = [NSMutableArray array];
	[self addAllSerialPortsToArray: serialPorts];
	for (int i = 0; i < [serialPorts count]; i++) {
		[avrdudePortPopUpButton addItemWithObjectValue: [serialPorts objectAtIndex: i]];
	}
	
	[self deviceChanged: nil];
	
	[mainWindow makeKeyAndOrderFront: nil];
	
	NSString *avrdudeConfig = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudeConfig"];
	NSString *avrdudePath = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePath"];

	if (!avrdudeConfig || !avrdudePath) {
		[self showPrefs: nil];
	}
	else {
		[self loadAvrdudeConfigs];
	}
    self.avrdudeOperationInProgress = NO;
    [self updateProjectsMenu];
    
    [projectNameTextField setDelegate: self];
}

- (void)loadPartDefinitions
{
	NSBundle *thisBundle = [NSBundle mainBundle];
	char buffer[1000];
	FILE *file = fopen([[thisBundle pathForResource: @"AVRFuses" ofType: @"parts"] UTF8String], "r");
	while(fgets(buffer, 1000, file) != NULL) {
		NSString *line = [[NSString alloc] initWithCString: buffer encoding:NSUTF8StringEncoding];
        [line autorelease];
		NSScanner *scanner = [NSScanner scannerWithString: line];

		NSString *settingPart = nil;
		NSString *settingFuse = nil;
		unsigned int settingMask = 0;
		unsigned int settingValue = 0;
		NSString *settingText = nil;
		
		[scanner scanUpToString: @"," intoString: &settingPart];
		[scanner setScanLocation:[scanner scanLocation] + 1];
		[scanner scanUpToString: @"," intoString: &settingFuse];
		[scanner setScanLocation:[scanner scanLocation] + 1];
		[scanner scanHexInt: &settingMask];
		[scanner setScanLocation:[scanner scanLocation] + 1];
		[scanner scanHexInt: &settingValue];
		[scanner setScanLocation:[scanner scanLocation] + 1];
		[scanner scanUpToString: @"\n" intoString: &settingText];
		
		// TODO see if this makes sense since we're adding to arrays and such
		[settingPart retain];
		[settingFuse retain];
		[settingText retain];
		
		PartDefinition *part = nil;
		if ([parts objectForKey: settingPart] == nil) {
			part = [[PartDefinition alloc] init];
            [part autorelease];
			part->name = settingPart;
			[parts setObject: part forKey: part->name];
		}
		else {
			part = [parts objectForKey: settingPart];
		}
		
		FuseDefinition *fuse = nil;
		if ([settingFuse isEqualToString: @"LOCKBIT"]) {
			if (part->lockbits == nil) {
				fuse = [[FuseDefinition alloc] init];
                [fuse autorelease];
				fuse->name = settingFuse;
				part->lockbits = fuse;
			}
			else {
				fuse = part->lockbits;
			}
		}
		else {
			if ([part->fuses objectForKey: settingFuse] == nil) {
				fuse = [[FuseDefinition alloc] init];
                [fuse autorelease];
				fuse->name = settingFuse;
				[part->fuses setObject: fuse forKey: fuse->name];
			}
			else {
				fuse = [part->fuses objectForKey: settingFuse];
			}
		}
		FuseSetting *fuseSetting = [[FuseSetting alloc] init];
        [fuseSetting autorelease];
		fuseSetting->fuse = fuse->name;
		fuseSetting->mask = settingMask & 0xff;
		fuseSetting->value = settingValue & 0xff;
		fuseSetting->text = settingText;
		
		[fuse->settings addObject: fuseSetting];
	}
	fclose(file);
}

- (void)loadSignaturesDefinitions
{
    NSBundle *thisBundle = [NSBundle mainBundle];
    char buffer[1000];
    FILE *file = fopen([[thisBundle pathForResource: @"Signatures" ofType: @"lst"] UTF8String], "r");
    while(fgets(buffer, 1000, file) != NULL) {
        NSString *line = [[NSString alloc] initWithCString: buffer encoding:NSUTF8StringEncoding];
        [line autorelease];
        NSScanner *scanner = [NSScanner scannerWithString: line];
        
        NSString *name = nil;
        unsigned int signature1 = 0;
        unsigned int signature2 = 0;
        unsigned int signature3 = 0;
        
        [scanner scanUpToString: @"," intoString: &name];
        [scanner setScanLocation:[scanner scanLocation] + 1];
        [scanner scanHexInt: &signature1];
        [scanner setScanLocation:[scanner scanLocation] + 1];
        [scanner scanHexInt: &signature2];
        [scanner setScanLocation:[scanner scanLocation] + 1];
        [scanner scanHexInt: &signature3];
        
        // TODO see if this makes sense since we're adding to arrays and such
        [name retain];
        
        Signature *signature = nil;
        signature = [[Signature alloc] init];
        [signature autorelease];
        signature->s1 = signature1;
        signature->s2 = signature2;
        signature->s3 = signature3;
        
        [signatures setObject: name forKey: signature];
    }
    fclose(file);
}


- (IBAction)deviceChanged:(id)sender
{
	selectedPart = [parts objectForKey: [[devicePopUpButton selectedItem] title]];
	
	[[NSUserDefaults standardUserDefaults] setObject: selectedPart->name forKey: @"lastSelectedPart"];
	
	[fuseSettings removeAllObjects];
	[lockbitSettings removeAllObjects];
	
	if ([selectedPart->fuses objectForKey:@"EXTENDED"] != nil) {
		FuseDefinition *fuse = [selectedPart->fuses objectForKey: @"EXTENDED"];
		for (int i = 0; i < [fuse->settings count]; i++) {
			[fuseSettings addObject: [fuse->settings objectAtIndex: i]];
		}
	}
	if ([selectedPart->fuses objectForKey:@"HIGH"] != nil) {
		FuseDefinition *fuse = [selectedPart->fuses objectForKey: @"HIGH"];
		for (int i = 0; i < [fuse->settings count]; i++) {
			[fuseSettings addObject: [fuse->settings objectAtIndex: i]];
		}
	}
	if ([selectedPart->fuses objectForKey:@"LOW"] != nil) {
		FuseDefinition *fuse = [selectedPart->fuses objectForKey: @"LOW"];
		for (int i = 0; i < [fuse->settings count]; i++) {
			[fuseSettings addObject: [fuse->settings objectAtIndex: i]];
		}
	}
	if (selectedPart->lockbits != nil) {
		FuseDefinition *fuse = selectedPart->lockbits;
		for (int i = 0; i < [fuse->settings count]; i++) {
			[lockbitSettings addObject: [fuse->settings objectAtIndex: i]];
		}
	}
	
	[fuses removeAllObjects];
	for (int i = 0; i < [[selectedPart->fuses allKeys] count]; i++) {
		[fuses setObject: [NSNumber numberWithUnsignedChar: 0xff] forKey: [[selectedPart->fuses allKeys] objectAtIndex: i]];
	}
    
	[fusesTableView reloadData];
	[lockbitsTableView reloadData];
    
    [self->lfuseText setHidden:[selectedPart->fuses objectForKey:@"LOW"] == nil];
    [self->hfuseText setHidden:[selectedPart->fuses objectForKey:@"HIGH"] == nil];
    [self->efuseText setHidden:[selectedPart->fuses objectForKey:@"EXTENDED"] == nil];
    [self->lfuseTextLabel setHidden:[selectedPart->fuses objectForKey:@"LOW"] == nil];
    [self->hfuseTextLabel setHidden:[selectedPart->fuses objectForKey:@"HIGH"] == nil];
    [self->efuseTextLabel setHidden:[selectedPart->fuses objectForKey:@"EXTENDED"] == nil];
    
    [self updateFuseTextFields];
}

- (IBAction)showPrefs:(id)sender
{
    [mainWindow beginSheet:prefsWindow completionHandler:nil];
	
	[self willChangeValueForKey: @"avrdudeAvailable"];
	[NSApp runModalForWindow:prefsWindow];
	[self didChangeValueForKey: @"avrdudeAvailable"];

    [NSApp endSheet:prefsWindow];
	
    [prefsWindow orderOut:self];	
	
	[self loadAvrdudeConfigs];
}

- (IBAction)closePrefs:(id)sender
{
    [NSApp endSheet:prefsWindow];
    [prefsWindow orderOut:self];
    [self loadAvrdudeConfigs];
	[NSApp stopModal];
}

- (IBAction)browseAvrdude:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories: NO];
	[openPanel setAllowsMultipleSelection: NO];
	[openPanel setMessage: @"Type / to browse to hidden directories."];
    [openPanel setDirectoryURL:[NSURL fileURLWithPath:@"/usr/local/bin"]];
	if ([openPanel runModal] == NSModalResponseOK) {
		[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [[openPanel URL] path] forKey: @"avrdudePath"];
		[self avrdudeChanged: nil];
	}
}

- (IBAction)avrdudeChanged: (id) sender
{
	[self loadAvrdudeConfigs];
}

- (IBAction)browseFlash:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories: NO];
	[openPanel setAllowsMultipleSelection: NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject: @"hex"]];
	if ([openPanel runModal] == NSModalResponseOK) {
		[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [[openPanel URL] path] forKey: @"lastSelectedFlash"];
	}
}

- (IBAction)browseEeprom:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories: NO];
	[openPanel setAllowsMultipleSelection: NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects: @"hex", @"eep", nil]];
	if ([openPanel runModal] == NSModalResponseOK) {
		[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: [[openPanel URL] path] forKey: @"lastSelectedEeprom"];
	}
}

- (void)log:(NSString *)s withAttributes:(NSDictionary *)attributes
{
	NSAttributedString *a = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", s]  attributes:attributes];
	[a autorelease];
	[[logTextView textStorage] appendAttributedString: a];
	[logTextView scrollRangeToVisible: NSMakeRange([[logTextView textStorage] length], [[logTextView textStorage] length])];
}

- (void)log:(NSString *)s
{
    [self log:s withAttributes:[NSDictionary dictionary]];
}

- (void)appendLog:(NSString *)s
{
	[self appendLog:s withAttributes:[NSDictionary dictionary]];
}

- (void)appendLog:(NSString *)s withAttributes:(NSDictionary *)attributes
{
    NSAttributedString *a = [[NSAttributedString alloc] initWithString:s attributes:attributes];
    [a autorelease];
    [[logTextView textStorage] appendAttributedString: a];
    [logTextView scrollRangeToVisible: NSMakeRange([[logTextView textStorage] length], [[logTextView textStorage] length])];
}

- (void)logStatus:(BOOL)status
{
	NSDictionary *green = 
	[NSDictionary dictionaryWithObject:[NSColor colorWithDeviceRed:0.0 green:1.0 blue:0.0 alpha:1.0]
								forKey:NSForegroundColorAttributeName];
	NSDictionary *red = 
	[NSDictionary dictionaryWithObject:[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:1.0]
								forKey:NSForegroundColorAttributeName];
	[self log:(status ? @"SUCCESS" : @"FAILURE") withAttributes:(status ? green : red)];
}

- (void)logCommandLine:(NSTask *)t
{
	if (![[NSUserDefaults standardUserDefaults] boolForKey:@"showCommandLines"]) {
		return;
	}
	NSDictionary *blue = 
	[NSDictionary dictionaryWithObject:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:1.0]
								forKey:NSForegroundColorAttributeName];
	NSMutableString *s = [NSMutableString stringWithFormat:@"\n%@", [t launchPath]];
	for (int i = 0, count = (int) [[t arguments] count]; i < count; i++) {
		[s appendFormat:@" %@", [[t arguments] objectAtIndex:i]];
	}
	[s appendString:@"\n"];
	[self log:[s description] withAttributes:blue];
}

- (BOOL) avrdudeAvailable
{
	NSString *avrdudeConfig = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudeConfig"];
	NSString *avrdudePath = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePath"];
	return (avrdudePath && avrdudeConfig && avrdudeVersion) && !self.avrdudeOperationInProgress;
}

- (void)loadAvrdudeConfigs
{
	NSString *avrdudePath = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePath"];

	[self willChangeValueForKey: @"avrdudeAvailable"];

	if (avrdudePath == nil) {
		[self didChangeValueForKey: @"avrdudeAvailable"];
		return;
	}
	
	avrdudeVersion = nil;
	[avrdudeConfigPopUpButton removeAllItems];
	
	NSMutableArray *avrdudeArguments = [[NSMutableArray alloc] init];
	[avrdudeArguments addObject: @"-v"];
	[avrdudeArguments addObject: @"-c"];
	[avrdudeArguments addObject: @"?"];
	
	[self log: @"Loading avrdude config..."];
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: avrdudePath];
	[task setArguments: avrdudeArguments];
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardError: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	NS_DURING
		[self logCommandLine:task];
		[task launch];
		[task waitUntilExit];
		NSData *data = [file readDataToEndOfFile];
		NSString *configs = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		NSArray *lines = [configs componentsSeparatedByString: @"\n"];
		for (int i = 0; i < [lines count]; i++) {
			NSString *line = [lines objectAtIndex: i];
			NSRange range;
			if (!avrdudeVersion) {
				range = [line rangeOfString: @"Version"];
				if (range.location != NSNotFound) {
					NSString *substr = [line substringFromIndex: range.location];
					NSArray *comps = [substr componentsSeparatedByString: @" "];
					comps = [[comps objectAtIndex: 1] componentsSeparatedByString: @","];
					avrdudeVersion = [comps objectAtIndex: 0];
				}
			}
			if (![line hasPrefix: @"   "] && [line hasPrefix: @"  "]) {
				NSArray *comps = [line componentsSeparatedByString: @" "];
				[avrdudeConfigPopUpButton addItemWithTitle: [comps objectAtIndex: 2]];
			}
		}
		[self logStatus:TRUE];
	NS_HANDLER
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText: @"Unable to execute avrdude."];
		[alert setInformativeText: @"Check that the path to avrdude is correct and that you are able to execute it normally."];
		[alert addButtonWithTitle: @"OK"];
        [alert beginSheetModalForWindow:([prefsWindow isVisible] ? prefsWindow : mainWindow)
                      completionHandler: nil
         ];
    
	NS_ENDHANDLER

	if (avrdudeVersion) {
		[mainWindow setTitle: [NSString stringWithFormat: @"AVRFuses (avrdude v%@)", avrdudeVersion]];
		if ([[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudeConfig"] != nil) {
			[avrdudeConfigPopUpButton selectItemWithTitle: [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudeConfig"]];
		}
	
		
	}
	else {
		[self logStatus:FALSE];
	}

	[self didChangeValueForKey: @"avrdudeAvailable"];
}

- (NSMutableArray *) defaultAvrdudeArguments
{
	NSString *avrdudePort = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePort"];
	NSString *avrdudeConfig = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudeConfig"];
	NSString *avrdudeSerialBaud = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudeSerialBaud"];
	NSString *avrdudeBitClock = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudeBitClock"];
	NSMutableArray *avrdudeArguments = [[NSMutableArray alloc] init];
	if (avrdudePort != nil && [avrdudePort length] > 0) {
		[avrdudeArguments addObject: @"-P"];
		[avrdudeArguments addObject: avrdudePort];
	}
	[avrdudeArguments addObject: @"-c"];
	[avrdudeArguments addObject: avrdudeConfig];
	if (avrdudeSerialBaud != nil && ![avrdudeSerialBaud isEqualToString: @"[Default]"]) {
		[avrdudeArguments addObject: @"-b"];
		[avrdudeArguments addObject: avrdudeSerialBaud];
	}
	[avrdudeArguments addObject: @"-p"];
	[avrdudeArguments addObject: selectedPart->name];
	//[avrdudeArguments addObject: @"-qq"];
    [avrdudeArguments addObject: @"-s"];
    if (avrdudeBitClock != nil && [avrdudeBitClock length] > 0) {
        [avrdudeArguments addObject: @"-B"];
        [avrdudeArguments addObject: avrdudeBitClock];
    }
	[avrdudeArguments autorelease];
	return avrdudeArguments;
}

- (void) execAvrdude:(NSMutableArray* _Nonnull)avrdudeArguments
        completionHandler:(void (^ _Nullable)(int returnCode))handler
{
    NSString *avrdudePath = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePath"];

    [self willChangeValueForKey: @"avrdudeAvailable"];
    self.avrdudeOperationInProgress = YES;
    [self didChangeValueForKey: @"avrdudeAvailable"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSTask *task = [[NSTask alloc] init];
        [task autorelease];
        [task setLaunchPath: avrdudePath];
        [task setArguments: avrdudeArguments];
        NSPipe *pipe = [NSPipe pipe];
        [task setStandardError: pipe];
        NSFileHandle *file = [pipe fileHandleForReading];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self logCommandLine:task];
        });
        [task launch];
        while (task.running) {
            [NSThread sleepForTimeInterval:0.005f];
            //NSData *data = [file readDataToEndOfFile];
            NSData *data = [file availableData];
            NSString *stdErr = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self appendLog: stdErr];
             });
            [stdErr autorelease];
        }
        //[task waitUntilExit];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self willChangeValueForKey: @"avrdudeAvailable"];
            self.avrdudeOperationInProgress = NO;
            [self didChangeValueForKey: @"avrdudeAvailable"];

            NSData *data = [file readDataToEndOfFile];
            NSString *stdErr = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
            [stdErr autorelease];
            NSArray *stdErrLines = [stdErr componentsSeparatedByString: @"\n"];
            for (int i = 0; i < [stdErrLines count]; i++) {
                NSString *line = [stdErrLines objectAtIndex: i];
                if ([line length] > 0) {
                    [self log: line];
                }
            }
            int status = [task terminationStatus];
            [self logStatus: status == 0];
            if (handler != nil) {
                handler(status);
            }
        });
    });
}

- (IBAction)programFuses:(id)sender
{
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];

	for (int i = 0; i < [[fuses allKeys] count]; i++) {
		NSString *fuseName = [[fuses allKeys] objectAtIndex: i];
		NSString *avrdudeFuseName = nil;
		if ([fuseName isEqualToString: @"EXTENDED"]) {
			avrdudeFuseName = @"efuse";
		}
		else if ([fuseName isEqualToString: @"LOW"]) {
			avrdudeFuseName = @"lfuse";
		}
		else if ([fuseName isEqualToString: @"HIGH"]) {
			avrdudeFuseName = @"hfuse";
		}
		// TODO this pattern in the rest of these functions should change with addition of lockbits
		else {
			continue;
		}
		[avrdudeArguments addObject: @"-U"];
		[avrdudeArguments addObject: [NSString stringWithFormat: @"%@:w:0x%02x:m", avrdudeFuseName, [[fuses objectForKey: fuseName] unsignedCharValue]]];
	}
	[self log: @"Programming fuses..."];

    [self execAvrdude: avrdudeArguments completionHandler: nil];
}

- (IBAction)readFuses:(id)sender
{
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];
	
	for (int i = 0; i < [[fuses allKeys] count]; i++) {
		NSString *fuseName = [[fuses allKeys] objectAtIndex: i];
		NSString *avrdudeFuseName = nil;
		if ([fuseName isEqualToString: @"EXTENDED"]) {
			avrdudeFuseName = @"efuse";
		}
		else if ([fuseName isEqualToString: @"LOW"]) {
			avrdudeFuseName = @"lfuse";
		}
		else if ([fuseName isEqualToString: @"HIGH"]) {
			avrdudeFuseName = @"hfuse";
		}
		else {
			continue;
		}
		[avrdudeArguments addObject: @"-U"];
		[avrdudeArguments addObject: [NSString stringWithFormat: @"%@:r:/tmp/%@.tmp:h", avrdudeFuseName, fuseName]];
	}
	[self log: @"Reading fuses..."];
    [self execAvrdude: avrdudeArguments completionHandler: ^(int returnCode) {
        if (returnCode == 0) {
            for (int i = 0; i < [[fuses allKeys] count]; i++) {
                NSString *fuseName = [[fuses allKeys] objectAtIndex: i];
                //NSLog(@"%@", fuseName);
                char buffer[1000];
                FILE *file = fopen([[NSString stringWithFormat: @"/tmp/%@.tmp", fuseName] UTF8String], "r");
                fgets(buffer, 1000, file);
                NSString *line = [[NSString alloc] initWithCString: buffer encoding:NSUTF8StringEncoding];
                [line autorelease];
                NSScanner *scanner = [NSScanner scannerWithString: line];
                unsigned int fuseValue;
                [scanner scanHexInt: &fuseValue];
                fclose(file);
                [fuses setObject: [NSNumber numberWithUnsignedChar: (fuseValue & 0xff)] forKey: fuseName];
            }
        }
        else {
            [self log: @"FAILED"];
        }
        [self updateFuseTextFields];
        [fusesTableView reloadData];
    }];
}

- (IBAction)verifyFuses:(id)sender
{
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];

	for (int i = 0; i < [[fuses allKeys] count]; i++) {
		NSString *fuseName = [[fuses allKeys] objectAtIndex: i];
		NSString *avrdudeFuseName = nil;
		if ([fuseName isEqualToString: @"EXTENDED"]) {
			avrdudeFuseName = @"efuse";
		}
		else if ([fuseName isEqualToString: @"LOW"]) {
			avrdudeFuseName = @"lfuse";
		}
		else if ([fuseName isEqualToString: @"HIGH"]) {
			avrdudeFuseName = @"hfuse";
		}
		else {
			continue;
		}
		[avrdudeArguments addObject: @"-U"];
		[avrdudeArguments addObject: [NSString stringWithFormat: @"%@:v:0x%02x:m", avrdudeFuseName, [[fuses objectForKey: fuseName] unsignedCharValue]]];
	}
	[self log: @"Verifying fuses..."];
    [self execAvrdude: avrdudeArguments completionHandler: ^(int returnCode) {
        [fusesTableView reloadData];
    }];
}

// TODO
/*
- (IBAction)programLockbits:(id)sender
{
	NSString *avrdudePath = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePath"];
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];
	
	for (int i = 0; i < [[fuses allKeys] count]; i++) {
		NSString *fuseName = [[fuses allKeys] objectAtIndex: i];
		NSString *avrdudeFuseName = nil;
		if ([fuseName isEqualToString: @"EXTENDED"]) {
			avrdudeFuseName = @"efuse";
		}
		else if ([fuseName isEqualToString: @"LOW"]) {
			avrdudeFuseName = @"lfuse";
		}
		else if ([fuseName isEqualToString: @"HIGH"]) {
			avrdudeFuseName = @"hfuse";
		}
		[avrdudeArguments addObject: @"-U"];
		[avrdudeArguments addObject: [NSString stringWithFormat: @"%@:w:0x%02x:m", avrdudeFuseName, [[fuses objectForKey: fuseName] unsignedCharValue]]];
	}
	[self log: @"Programming fuses..."];
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: avrdudePath];
	[task setArguments: avrdudeArguments];
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardError: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	[task launch];
	[task waitUntilExit];
	NSData *data = [file readDataToEndOfFile];
	NSString *stdErr = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	NSArray *stdErrLines = [stdErr componentsSeparatedByString: @"\n"];
	for (int i = 0; i < [stdErrLines count]; i++) {
		NSString *line = [stdErrLines objectAtIndex: i];
		if ([line length] > 0) {
			[self log: line];
		}
	}
	if ([task terminationStatus] == 0) {
		[self log: @"SUCCESS"];
	}
	else {
		[self log: @"FAILED"];
	}
}

- (IBAction)readLockbits:(id)sender
{
	NSString *avrdudePath = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePath"];
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];
	
	NSString *fuseName = @"LOCKBIT";
	NSString *avrdudeFuseName = @"lock";
	[avrdudeArguments addObject: @"-U"];
	[avrdudeArguments addObject: [NSString stringWithFormat: @"%@:r:/tmp/%@.tmp:h", avrdudeFuseName, fuseName]];

	[self log: @"Reading lock bits..."];
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: avrdudePath];
	[task setArguments: avrdudeArguments];
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardError: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	[task launch];
	[task waitUntilExit];
	NSData *data = [file readDataToEndOfFile];
	NSString *stdErr = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	NSArray *stdErrLines = [stdErr componentsSeparatedByString: @"\n"];
	for (int i = 0; i < [stdErrLines count]; i++) {
		NSString *line = [stdErrLines objectAtIndex: i];
		if ([line length] > 0) {
			[self log: line];
		}
	}
	if ([task terminationStatus] == 0) {
		[self log: @"SUCCESS"];
		char buffer[1000];
		FILE *file = fopen([[NSString stringWithFormat: @"/tmp/%@.tmp", fuseName] cString], "r");
		fgets(buffer, 1000, file);
		NSString *line = [[NSString alloc] initWithCString: buffer];
		NSScanner *scanner = [NSScanner scannerWithString: line];
		unsigned int fuseValue;
		[scanner scanHexInt: &fuseValue];
		fclose(file);
		[fuses setObject: [NSNumber numberWithUnsignedChar: (fuseValue & 0xff)] forKey: fuseName];
	}
	else {
		[self log: @"FAILED"];
	}
	[lockbitsTableView reloadData];
}

- (IBAction)verifyLockbits:(id)sender
{
	NSString *avrdudePath = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePath"];
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];

	for (int i = 0; i < [[fuses allKeys] count]; i++) {
		NSString *fuseName = [[fuses allKeys] objectAtIndex: i];
		NSString *avrdudeFuseName = nil;
		if ([fuseName isEqualToString: @"EXTENDED"]) {
			avrdudeFuseName = @"efuse";
		}
		else if ([fuseName isEqualToString: @"LOW"]) {
			avrdudeFuseName = @"lfuse";
		}
		else if ([fuseName isEqualToString: @"HIGH"]) {
			avrdudeFuseName = @"hfuse";
		}
		[avrdudeArguments addObject: @"-U"];
		[avrdudeArguments addObject: [NSString stringWithFormat: @"%@:v:0x%02x:m", avrdudeFuseName, [[fuses objectForKey: fuseName] unsignedCharValue]]];
	}
	[self log: @"Verifying fuses..."];
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: avrdudePath];
	[task setArguments: avrdudeArguments];
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardError: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	[task launch];
	[task waitUntilExit];
	NSData *data = [file readDataToEndOfFile];
	NSString *stdErr = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	NSArray *stdErrLines = [stdErr componentsSeparatedByString: @"\n"];
	for (int i = 0; i < [stdErrLines count]; i++) {
		NSString *line = [stdErrLines objectAtIndex: i];
		if ([line length] > 0) {
			[self log: line];
		}
	}
	if ([task terminationStatus] == 0) {
		[self log: @"SUCCESS"];
	}
	else {
		[self log: @"FAILED"];
	}
	[fusesTableView reloadData];
}
*/

- (IBAction)verifyFlash:(id)sender
{
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];
	
	[avrdudeArguments addObject: @"-U"];
	[avrdudeArguments addObject: [NSString stringWithFormat: @"flash:v:%@", 
		[[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedFlash"]]];
	[self log: @"Verifying flash..."];
    [self execAvrdude: avrdudeArguments completionHandler: nil];
}

- (IBAction)programFlash:(id)sender
{
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];
	
	[avrdudeArguments addObject: @"-U"];
	[avrdudeArguments addObject: [NSString stringWithFormat: @"flash:w:%@", 
		[[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedFlash"]]];
	[self log: @"Programming flash..."];
    [self execAvrdude: avrdudeArguments completionHandler: nil];
}


- (IBAction)readFlash:(id)sender
{
	NSString *filename = [[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedFlash"];
	if (sender != nil && [[NSFileManager defaultManager] fileExistsAtPath: filename]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText: 
			[NSString stringWithFormat: @"\"%@\" already exists. Do you want to replace it?", 
				[[NSFileManager defaultManager] displayNameAtPath: filename]]];
		[alert setInformativeText: @"A file or folder with the same name already exists. Replacing it will overwrite it's current contents."];
		[alert addButtonWithTitle: @"Replace"];
		[alert addButtonWithTitle: @"Cancel"];
        [alert beginSheetModalForWindow: mainWindow
                      completionHandler: ^(NSModalResponse returnCode) {
                          [[alert window] orderOut: self];
                          if (returnCode == NSAlertFirstButtonReturn) {
                              [self readFlash: nil];
                          }
                      }];
		return;
	}

	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];
	
	[avrdudeArguments addObject: @"-U"];
	[avrdudeArguments addObject: [NSString stringWithFormat: @"flash:r:%@:i", filename]];
	[self log: @"Reading flash..."];
    [self execAvrdude: avrdudeArguments completionHandler: nil];
}

- (IBAction)verifyEeprom:(id)sender
{
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];
	
	[avrdudeArguments addObject: @"-U"];
	[avrdudeArguments addObject: [NSString stringWithFormat: @"eeprom:v:%@", 
		[[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedEeprom"]]];
	[self log: @"Verifying EEPROM..."];
    [self execAvrdude: avrdudeArguments completionHandler: nil];
}

- (IBAction)programEeprom:(id)sender
{
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];
	
	[avrdudeArguments addObject: @"-U"];
	[avrdudeArguments addObject: [NSString stringWithFormat: @"eeprom:w:%@", 
		[[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedEeprom"]]];
	[self log: @"Programming EEPROM..."];
    [self execAvrdude: avrdudeArguments completionHandler: nil];
}

- (IBAction)readEeprom:(id)sender
{
	NSString *filename = [[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedEeprom"];
	if (sender != nil && [[NSFileManager defaultManager] fileExistsAtPath: filename]) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText: 
			[NSString stringWithFormat: @"\"%@\" already exists. Do you want to replace it?", 
				[[NSFileManager defaultManager] displayNameAtPath: filename]]];
		[alert setInformativeText: @"A file or folder with the same name already exists. Replacing it will overwrite it's current contents."];
		[alert addButtonWithTitle: @"Replace"];
		[alert addButtonWithTitle: @"Cancel"];
        [alert beginSheetModalForWindow: mainWindow
                completionHandler: ^(NSModalResponse returnCode) {
                    [[alert window] orderOut: self];
                    if (returnCode == NSAlertFirstButtonReturn) {
                        [self readEeprom: nil];
                    }
                }];
		return;
	}
	
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];
	
	[avrdudeArguments addObject: @"-U"];
	[avrdudeArguments addObject: [NSString stringWithFormat: @"eeprom:r:%@:i", filename]];
	[self log: @"Reading EEPROM..."];
    [self execAvrdude: avrdudeArguments completionHandler: nil];
}

- (IBAction)eraseDevice:(id)sender
{
	NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];

	[avrdudeArguments addObject: @"-e"];
	[self log: @"Erasing chip..."];
    [self execAvrdude: avrdudeArguments completionHandler: nil];
}

- (IBAction)autodetectDevice:(id)sender
{
    NSMutableArray *avrdudeArguments = [self defaultAvrdudeArguments];
    
    [avrdudeArguments addObject: @"-F"];
    [avrdudeArguments addObject: @"-U"];
    [avrdudeArguments addObject: @"signature:r:/tmp/SIGNATURE.tmp:h"];

    [self log: @"Reading signature..."];
    
    [self execAvrdude:avrdudeArguments completionHandler: ^(int returnCode) {
        if (returnCode == 0) {
            char buffer[1000];
            FILE *file = fopen("/tmp/SIGNATURE.tmp", "r");
            fgets(buffer, 1000, file);
            NSString *line = [[NSString alloc] initWithCString: buffer encoding:NSUTF8StringEncoding];
            [line autorelease];
            NSScanner *scanner = [NSScanner scannerWithString: line];
            NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@","];
            unsigned int signByte1, signByte2, signByte3;
            [scanner setCharactersToBeSkipped:separatorSet];
            [scanner scanHexInt: &signByte1];
            [scanner scanHexInt: &signByte2];
            [scanner scanHexInt: &signByte3];
            fclose(file);
            
            Signature *signature = [[Signature alloc] init];
            signature->s1 = signByte1;
            signature->s2 = signByte2;
            signature->s3 = signByte3;
            
            NSString *name = [signatures objectForKey:signature];
            if (name != nil) {
                [self log: name];
            }
            NSInteger index = name != nil ? [devicePopUpButton indexOfItemWithTitle: name] : -1;
            if (index >= 0) {
                [devicePopUpButton selectItemAtIndex: index];
                [self deviceChanged: nil];
            } else {
                [self log: @"Device not found"];
            }
        }
    }];
}

- (void)tableViewDoubleClick: (NSTableView *) tableView
{
	if (![self avrdudeAvailable]) {
		return;
	}

	NSMutableArray *settings = nil;
	if (tableView == fusesTableView) {
		settings = fuseSettings;
	}
	else if (tableView == lockbitsTableView) {
		settings = lockbitSettings;
	}

	FuseSetting *fuseSetting = [settings objectAtIndex: [tableView selectedRow]];
    
    if (!fuseSetting) {
        return;
    }
	
	unsigned char fuseValue = [[fuses objectForKey: fuseSetting->fuse] intValue];

	BOOL singleElementGroup = YES;
	for (int i = 0; i < [settings count]; i++) {
		FuseSetting *fuseSetting1 = [settings objectAtIndex: i];
		if (fuseSetting1 != fuseSetting && 
			[fuseSetting1->fuse isEqualToString: fuseSetting->fuse] &&
			fuseSetting1->mask == fuseSetting->mask) {
			singleElementGroup = NO;
			break;
		}
	}
	
	if (singleElementGroup) {
		fuseValue ^= fuseSetting->mask;
	}
	else if ((fuseValue & fuseSetting->mask) != fuseSetting->value) {
		fuseValue |= fuseSetting->mask;
		fuseValue &= (~(fuseSetting->mask) | fuseSetting->value);
	}

	[fuses setObject: [NSNumber numberWithUnsignedChar: fuseValue] forKey: fuseSetting->fuse];
	
	[tableView reloadData];
    [self updateFuseTextFields];
}

- (IBAction)lfuseTextUpdated:(id)sender {
    NSString *fuseName = @"LOW";
    NSTextField *field = lfuseText;
    
    NSString *s = [field stringValue];
    
    NSScanner *scanner = [NSScanner scannerWithString: s];
    unsigned int value;
    if (![scanner scanHexInt: &value]) {
        [field setStringValue:[NSString stringWithFormat:@"0x%2x", [[fuses objectForKey:fuseName] unsignedCharValue]]];
    }
    [fuses setObject: [NSNumber numberWithUnsignedChar: (value & 0xff)] forKey: fuseName];
    [self updateFuseTextFields];
	[fusesTableView reloadData];
}

- (IBAction)hfuseTextUpdated:(id)sender {
    NSString *fuseName = @"HIGH";
    NSTextField *field = hfuseText;
    
    NSString *s = [field stringValue];
    
    NSScanner *scanner = [NSScanner scannerWithString: s];
    unsigned int value;
    if (![scanner scanHexInt: &value]) {
        [field setStringValue:[NSString stringWithFormat:@"0x%2x", [[fuses objectForKey:fuseName] unsignedCharValue]]];
    }
    [fuses setObject: [NSNumber numberWithUnsignedChar: (value & 0xff)] forKey: fuseName];
    [self updateFuseTextFields];
	[fusesTableView reloadData];
}

- (IBAction)efuseTextUpdated:(id)sender {
    NSString *fuseName = @"EXTENDED";
    NSTextField *field = efuseText;
    
    NSString *s = [field stringValue];
    
    NSScanner *scanner = [NSScanner scannerWithString: s];
    unsigned int value;
    if (![scanner scanHexInt: &value]) {
        [field setStringValue:[NSString stringWithFormat:@"0x%2x", [[fuses objectForKey:fuseName] unsignedCharValue]]];
    }
    [fuses setObject: [NSNumber numberWithUnsignedChar: (value & 0xff)] forKey: fuseName];
    [self updateFuseTextFields];
	[fusesTableView reloadData];
}

- (void)updateFuseTextFields {
	for (int i = 0; i < [[fuses allKeys] count]; i++) {
		NSString *fuseName = [[fuses allKeys] objectAtIndex: i];
        unsigned char fuseValue = [[fuses objectForKey: fuseName] unsignedCharValue];
		if ([fuseName isEqualToString: @"EXTENDED"]) {
            efuseText.stringValue = [NSString stringWithFormat:@"0x%02x", fuseValue];
		}
		else if ([fuseName isEqualToString: @"LOW"]) {
            lfuseText.stringValue = [NSString stringWithFormat:@"0x%02x", fuseValue];
		}
		else if ([fuseName isEqualToString: @"HIGH"]) {
            hfuseText.stringValue = [NSString stringWithFormat:@"0x%02x", fuseValue];
		}
		else {
			continue;
		}
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == fusesTableView) {
		return (int) [fuseSettings count];
	}
	else if (tableView == lockbitsTableView) {
		return (int) [lockbitSettings count];
	}
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *) column row:(int)row
{
	NSMutableArray *settings = nil;
	if (tableView == fusesTableView) {
		settings = fuseSettings;
	}
	else if (tableView == lockbitsTableView) {
		settings = lockbitSettings;
	}
	if ([[column identifier] isEqual:@"checkbox"]) {
		FuseSetting *fuseSetting = [settings objectAtIndex: row];
        if (!fuseSetting) {
            return nil;
        }
		unsigned char fuseValue = [[fuses objectForKey: fuseSetting->fuse] intValue];
		return ((fuseValue & fuseSetting->mask) == fuseSetting->value) ? @"1" : @"0";
	}
	else if ([[column identifier] isEqual:@"fuse"]) {
		FuseSetting *fuseSetting = [settings objectAtIndex: row];
        if (!fuseSetting) {
            return nil;
        }
		return fuseSetting->text;
	}
	
	return nil;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication * _Nullable) theApplication
{
	return YES;
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
	if (offset == 0) {
		return 388.0;
	}
	return 0.0;
}

- (NSString * _Nullable)getNextSerialPort:(io_iterator_t)serialPortIterator
{
	NSString *serialPort = nil;
	io_object_t serialService = IOIteratorNext(serialPortIterator);
	if (serialService != 0) {
		CFStringRef modemName = (CFStringRef)IORegistryEntryCreateCFProperty(serialService, CFSTR(kIOTTYDeviceKey), kCFAllocatorDefault, 0);
		CFStringRef bsdPath = (CFStringRef)IORegistryEntryCreateCFProperty(serialService, CFSTR(kIOCalloutDeviceKey), kCFAllocatorDefault, 0);
		if (modemName && bsdPath) {
			serialPort = [NSString stringWithString: (NSString *) bsdPath];
		}
        if (modemName) {
            CFRelease(modemName);
        }
        if (bsdPath) {
            CFRelease(bsdPath);
        }
		
		// We have sucked this service dry of information so release it now.
		(void)IOObjectRelease(serialService);
	}
	return serialPort;
}

- (void)addAllSerialPortsToArray:(NSMutableArray * _Nonnull)array
{
	NSString *serialPort;
	kern_return_t kernResult; 
	CFMutableDictionaryRef classesToMatch;
	io_iterator_t serialPortIterator;
	
	// Serial devices are instances of class IOSerialBSDClient
	classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue);
	if (classesToMatch != NULL) {
		CFDictionarySetValue(classesToMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDAllTypes));

		// This function decrements the refcount of the dictionary passed it
		kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, classesToMatch, &serialPortIterator);    
		if (kernResult == KERN_SUCCESS) {			
			while ((serialPort = [self getNextSerialPort:serialPortIterator]) != nil) {
				[array addObject: serialPort];
			}
			(void)IOObjectRelease(serialPortIterator);
		} else {
			NSLog(@"IOServiceGetMatchingServices returned %d", kernResult);
		}
	} else {
		NSLog(@"IOServiceMatching returned a NULL dictionary.");
	}
}

- (IBAction)clearLog:(id)sender {
    logTextView.string = @"";
}

- (IBAction)copyLog:(id)sender {
    [logTextView copy:self];
}

- (void)prepareNewProjectWindow {
    [projectDevicePopUpButton selectItemWithTitle: devicePopUpButton.selectedItem.title];
    editedProjectName = nil;
    
    NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedFlash"];
    if (path == nil) {
        path = @"";
    }
    NSString *projectName = [[path lastPathComponent] stringByDeletingPathExtension];
    projectNameTextField.stringValue = projectName;

    [projectFlashTextField setStringValue: path];
    path = [[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedEeprom"];
    if (path == nil) {
        path = @"";
    }
    [projectEepromTextField setStringValue: path];
    
    for (int i = 0; i < [[fuses allKeys] count]; i++) {
        NSString *fuseName = [[fuses allKeys] objectAtIndex: i];
        unsigned char fuseValue = [[fuses objectForKey: fuseName] unsignedCharValue];
        if ([fuseName isEqualToString: @"EXTENDED"]) {
            self->projectExtFuseTextField.stringValue = [NSString stringWithFormat:@"0x%02x", fuseValue];
        } else if ([fuseName isEqualToString: @"LOW"]) {
            self->projectLowFuseTextField.stringValue = [NSString stringWithFormat:@"0x%02x", fuseValue];
        } else if ([fuseName isEqualToString: @"HIGH"]) {
            self->projectHighFuseTextField.stringValue = [NSString stringWithFormat:@"0x%02x", fuseValue];
        }
    }
    projectDeleteButton.hidden = YES;
}

- (void)prepareEditProjectWindow: (NSString*) name
{
    editedProjectName = name;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *projects = [defaults dictionaryForKey: @"projects"];
    NSDictionary *project = projects[name];
    
    projectNameTextField.stringValue = project[@"name"];
    [projectDevicePopUpButton selectItemWithTitle: project[@"device"]];
    projectFlashTextField.stringValue = project[@"flash"];
    projectEepromTextField.stringValue = project[@"eeprom"];
    projectExtFuseTextField.stringValue = project[@"fuse-e"];
    projectLowFuseTextField.stringValue = project[@"fuse-l"];
    projectHighFuseTextField.stringValue = project[@"fuse-h"];
    
    [self projectDeviceChanged: nil];
    projectDeleteButton.hidden = NO;
}

- (void)updateProjectsMenu
{
    while (projectsMenu.numberOfItems > 3) {
        [projectsMenu removeItemAtIndex: 3];
    }
    [projectsEditMenu removeAllItems];
    
    NSDictionary *projects = [[NSUserDefaults standardUserDefaults] dictionaryForKey: @"projects"];
    for (id key in projects) {
        [projectsMenu addItemWithTitle: projects[key][@"name"] action: @selector(openProject:) keyEquivalent: @""];
        [projectsEditMenu addItemWithTitle: projects[key][@"name"] action: @selector(editProject:) keyEquivalent: @""];
    }
    [[NSApp mainMenu] update];
}

- (IBAction)openProject: (id)sender
{
    NSString *name = [sender title];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *projects = [defaults dictionaryForKey: @"projects"];
    NSDictionary *project = projects[name];
    
    [devicePopUpButton selectItemWithTitle: project[@"device"]];
    [self deviceChanged: nil];
    
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: project[@"flash"] forKey: @"lastSelectedFlash"];
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue: project[@"eeprom"] forKey: @"lastSelectedEeprom"];
    efuseText.stringValue = project[@"fuse-e"];
    [self efuseTextUpdated: nil];
    lfuseText.stringValue = project[@"fuse-l"];
    [self lfuseTextUpdated: nil];
    hfuseText.stringValue = project[@"fuse-h"];
    [self hfuseTextUpdated: nil];
}

- (IBAction)editProject: (id)sender
{
    NSString *name = [sender title];
    [self prepareEditProjectWindow: name];
    [mainWindow beginSheet:projectWindow completionHandler:nil];
    [NSApp runModalForWindow:projectWindow];
    
    [NSApp endSheet:projectWindow];
}

- (IBAction)newProject:(id)sender
{
    [self prepareNewProjectWindow];
    [mainWindow beginSheet:projectWindow completionHandler:nil];
    [NSApp runModalForWindow:projectWindow];
    
    [NSApp endSheet:projectWindow];
}

- (IBAction)closeProjectDialog:(id)sender
{
    [NSApp endSheet:projectWindow];
    [projectWindow orderOut:self];
    [NSApp stopModal];
}

- (IBAction)projectDeviceChanged:(id)sender
{
    PartDefinition *part = [parts objectForKey: [[projectDevicePopUpButton selectedItem] title]];
    
    BOOL hasLowFuses = [part->fuses objectForKey:@"LOW"] != nil;
    BOOL hasHighFuses = [part->fuses objectForKey:@"HIGH"] != nil;
    BOOL hasExtFuses = [part->fuses objectForKey:@"EXTENDED"] != nil;
    projectLowFuseTextField.hidden = !hasLowFuses;
    projectHighFuseTextField.hidden = !hasHighFuses;
    projectExtFuseTextField.hidden = !hasExtFuses;
    projectLowFuseTextLabel.hidden = !hasLowFuses;
    projectHighFuseTextLabel.hidden = !hasHighFuses;
    projectExtFuseTextLabel.hidden = !hasExtFuses;
}


- (IBAction)saveProject:(id)sender
{
    NSString *projectName = projectNameTextField.stringValue;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *projects = [defaults dictionaryForKey: @"projects"];
    [projects autorelease];
    NSMutableDictionary *mutProjects = [[NSMutableDictionary alloc] initWithDictionary:projects copyItems:false];
    [mutProjects autorelease];
    if (projects == nil) {
        projects = @{};
    }
    NSDictionary *prj = @{
                          @"name": projectNameTextField.stringValue,
                          @"device": projectDevicePopUpButton.title,
                          @"flash": projectFlashTextField.stringValue,
                          @"eeprom": projectEepromTextField.stringValue,
                          @"fuse-h": projectHighFuseTextField.stringValue,
                          @"fuse-l": projectLowFuseTextField.stringValue,
                          @"fuse-e": projectExtFuseTextField.stringValue
                          };
    mutProjects[projectName] = prj;
    if (![editedProjectName isEqualToString: projectName] && [mutProjects doesContain: editedProjectName]) {
        [mutProjects removeObjectForKey:editedProjectName];
    }
    [defaults setObject:mutProjects forKey: @"projects"];
    [NSApp endSheet:projectWindow];
    [projectWindow orderOut:self];
    [NSApp stopModal];
    [self updateProjectsMenu];
}

- (IBAction)deleteProject:(id)sender
{
    [NSApp endSheet:projectWindow];
    [projectWindow orderOut:self];
    [NSApp stopModal];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *projects = [defaults dictionaryForKey: @"projects"];
    [projects autorelease];
    if (projects != nil && editedProjectName != nil) {
        NSMutableDictionary *mutProjects = [[NSMutableDictionary alloc] initWithDictionary:projects copyItems:false];
        [mutProjects autorelease];
        [mutProjects removeObjectForKey:editedProjectName];
        [defaults setObject:mutProjects forKey: @"projects"];
        [self updateProjectsMenu];
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    if (notification.object == projectNameTextField) {
        NSString *trimmedName = [projectNameTextField.stringValue stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        projectOkButton.enabled = ![trimmedName isEqualToString: @""];
    }
}

- (IBAction)projectBrowseFlash:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories: NO];
    [openPanel setAllowsMultipleSelection: NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObject: @"hex"]];
    if ([openPanel runModal] == NSModalResponseOK) {
        projectFlashTextField.stringValue = openPanel.URL.path;
    }
}

- (IBAction)projectBrowseEeprom:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories: NO];
    [openPanel setAllowsMultipleSelection: NO];
    [openPanel setAllowedFileTypes:[NSArray arrayWithObjects: @"hex", @"eep", nil]];
    if ([openPanel runModal] == NSModalResponseOK) {
        projectEepromTextField.stringValue = openPanel.URL.path;
    }
}


@end
