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
	NSMutableArray *lockbitSettings;
	NSString *avrdudeVersion;
}

- (void)awakeFromNib;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) theApplication;
- (void)loadPartDefinitions;
- (void)loadAvrdudeConfigs;

- (BOOL) avrdudeAvailable;

- (NSString *)getNextSerialPort:(io_iterator_t)serialPortIterator;
- (void)addAllSerialPortsToArray:(NSMutableArray *)array;

@end
