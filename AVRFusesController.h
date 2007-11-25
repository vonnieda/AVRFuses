/* AVRFusesController */

#import <Cocoa/Cocoa.h>
#import "AVRFusesWindowController.h"
#import "PartDefinition.h"

@interface AVRFusesController : AVRFusesWindowController
{
	NSMutableDictionary *parts;
	PartDefinition *selectedPart;
	NSMutableDictionary *fuses;
	NSMutableArray *fuseSettings;
	NSString *avrdudeVersion;
}

- (void)awakeFromNib;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) theApplication;
- (void)loadPartDefinitions;
- (void)loadAvrdudeConfigs;
@end
