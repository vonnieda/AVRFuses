#import "AVRFusesController.h"

@implementation AVRFusesController
- (void)awakeFromNib
{
	parts = [[NSMutableDictionary alloc] init];
	selectedPart = nil;
	fuses = [[NSMutableDictionary alloc] init];
	fuseSettings = [[NSMutableArray alloc] init];
	
	[fusesTableView setDoubleAction: @selector(tableViewDoubleClick)];
	
	[self loadPartDefinitions];
	
	for (NSString *partName in [[parts allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
		[devicePopUpButton addItemWithTitle: partName];
	}
	
	if ([[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedPart"] != nil) {
		[devicePopUpButton selectItemWithTitle: [[NSUserDefaults standardUserDefaults] stringForKey: @"lastSelectedPart"]];
	}
	
	[self deviceChanged: nil];
}

- (void)loadPartDefinitions
{
	NSBundle *thisBundle = [NSBundle mainBundle];
	char buffer[1000];
	FILE *file = fopen([[thisBundle pathForResource: @"AVRFuses" ofType: @"parts"] UTF8String], "r");
	while(fgets(buffer, 1000, file) != NULL) {
		NSString *line = [[NSString alloc] initWithCString: buffer];
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
			part->name = settingPart;
			[parts setObject: part forKey: part->name];
		}
		else {
			part = [parts objectForKey: settingPart];
		}
		
		FuseDefinition *fuse = nil;
		if ([part->fuses objectForKey: settingFuse] == nil) {
			fuse = [[FuseDefinition alloc] init];
			fuse->name = settingFuse;
			[part->fuses setObject: fuse forKey: fuse->name];
		}
		else {
			fuse = [part->fuses objectForKey: settingFuse];
		}
		FuseSetting *fuseSetting = [[FuseSetting alloc] init];
		fuseSetting->fuse = fuse->name;
		fuseSetting->mask = settingMask & 0xff;
		fuseSetting->value = settingValue & 0xff;
		fuseSetting->text = settingText;
		
		[fuse->settings addObject: fuseSetting];
	}
	fclose(file);
}


- (IBAction)deviceChanged:(id)sender
{
	selectedPart = [parts objectForKey: [[devicePopUpButton selectedItem] title]];
	
	[[NSUserDefaults standardUserDefaults] setObject: selectedPart->name forKey: @"lastSelectedPart"];
	
	[fuseSettings removeAllObjects];
	
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
	
	[fusesTableView reloadData];
	
	[fuses removeAllObjects];
	for (int i = 0; i < [[selectedPart->fuses allKeys] count]; i++) {
		[fuses setObject: [NSNumber numberWithUnsignedChar: 0xff] forKey: [[selectedPart->fuses allKeys] objectAtIndex: i]];
	}
}

- (IBAction)showPrefs:(id)sender
{
	[NSApp beginSheet:prefsWindow
		modalForWindow:mainWindow 
		modalDelegate:nil 
		didEndSelector:nil 
		contextInfo:nil];
	
	[NSApp runModalForWindow:prefsWindow];

    [NSApp endSheet:prefsWindow];
	
    [prefsWindow orderOut:self];	
}

- (void)log:(NSString *)s
{
	NSAttributedString *a = [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@\n", s]];
	[a autorelease];
	[[logTextView textStorage] appendAttributedString: a];
	[logTextView scrollRangeToVisible: NSMakeRange([[logTextView textStorage] length], [[logTextView textStorage] length])];
}

- (IBAction)fusesProgram:(id)sender
{
	NSString *avrdudePort = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePort"];
	NSString *avrdudeConfig = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudeConfig"];
	NSString *avrdudePath = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePath"];
	NSMutableArray *avrdudeArguments = [[NSMutableArray alloc] init];
	[avrdudeArguments addObject: @"-P"];
	[avrdudeArguments addObject: avrdudePort];
	[avrdudeArguments addObject: @"-c"];
	[avrdudeArguments addObject: avrdudeConfig];
	[avrdudeArguments addObject: @"-p"];
	[avrdudeArguments addObject: selectedPart->name];
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
	NSTask *task = [NSTask launchedTaskWithLaunchPath: avrdudePath arguments: avrdudeArguments];
	[task waitUntilExit];
	[self log: [NSString stringWithFormat: @"Exit code: %d", [task terminationStatus]]];
	if ([task terminationStatus] == 0) {
		[self log: @"Success!"];
	}
}

- (IBAction)fusesRead:(id)sender
{
	NSString *avrdudePort = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePort"];
	NSString *avrdudeConfig = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudeConfig"];
	NSString *avrdudePath = [[NSUserDefaults standardUserDefaults] stringForKey: @"avrdudePath"];
	NSMutableArray *avrdudeArguments = [[NSMutableArray alloc] init];
	[avrdudeArguments addObject: @"-P"];
	[avrdudeArguments addObject: avrdudePort];
	[avrdudeArguments addObject: @"-c"];
	[avrdudeArguments addObject: avrdudeConfig];
	[avrdudeArguments addObject: @"-p"];
	[avrdudeArguments addObject: selectedPart->name];
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
		[avrdudeArguments addObject: [NSString stringWithFormat: @"%@:r:/tmp/%@.tmp:h", avrdudeFuseName, fuseName]];
	}
	[self log: @"Reading fuses..."];
	NSTask *task = [NSTask launchedTaskWithLaunchPath: avrdudePath arguments: avrdudeArguments];
	[task waitUntilExit];
	[self log: [NSString stringWithFormat: @"Exit code: %d", [task terminationStatus]]];
	if ([task terminationStatus] == 0) {
		[self log: @"Success!"];
		for (int i = 0; i < [[fuses allKeys] count]; i++) {
			NSString *fuseName = [[fuses allKeys] objectAtIndex: i];
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
	}
	[fusesTableView reloadData];
}

- (IBAction)closePrefs:(id)sender
{
	[NSApp stopModal];
}

- (void)tableViewDoubleClick
{
	FuseSetting *fuseSetting = [fuseSettings objectAtIndex: [fusesTableView selectedRow]];
	
	unsigned char fuseValue = [[fuses objectForKey: fuseSetting->fuse] intValue];

	if ((fuseValue & fuseSetting->mask) != fuseSetting->value) {
		fuseValue |= fuseSetting->mask;
		fuseValue &= (~(fuseSetting->mask) | fuseSetting->value);
	}
	
	
	[fuses setObject: [NSNumber numberWithUnsignedChar: fuseValue] forKey: fuseSetting->fuse];
	
	[fusesTableView reloadData];
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [fuseSettings count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *) column row:(int)row
{
	if ([[column identifier] isEqual:@"checkbox"]) {
		FuseSetting *fuseSetting = [fuseSettings objectAtIndex: row];
		unsigned char fuseValue = [[fuses objectForKey: fuseSetting->fuse] intValue];
		return ((fuseValue & fuseSetting->mask) == fuseSetting->value) ? @"1" : @"0";
	}
	else if ([[column identifier] isEqual:@"fuse"]) {
		FuseSetting *fuseSetting = [fuseSettings objectAtIndex: row];
		return fuseSetting->text;
	}
	
	return nil;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) theApplication
{
	return YES;
}
@end
