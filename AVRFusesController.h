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
    NSMutableDictionary *signatures;
    
    NSString *editedProjectName;
}

@property (atomic, assign) BOOL avrdudeOperationInProgress;

- (void)awakeFromNib;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication * _Nullable) theApplication;
- (void)loadPartDefinitions;
- (void)loadSignaturesDefinitions;
- (void)loadAvrdudeConfigs;

- (BOOL) avrdudeAvailable;

- (NSString * _Nullable)getNextSerialPort:(io_iterator_t)serialPortIterator;
- (void)addAllSerialPortsToArray:(NSMutableArray * _Nonnull)array;

- (void)execAvrdude: (NSMutableArray * _Nonnull)avrdudeArguments completionHandler:(void (^ _Nullable)(int returnCode))handler;
@end
