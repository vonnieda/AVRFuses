/* AVRFusesWindowController */

#import <Cocoa/Cocoa.h>

@interface AVRFusesWindowController : NSObject
{
    IBOutlet NSPopUpButton *devicePopUpButton;
    IBOutlet NSTableView *fusesTableView;
    IBOutlet NSTextView *logTextView;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSWindow *prefsWindow;
    IBOutlet NSTabView *tabView;
	IBOutlet NSTextField *avrdudeTextField;
	//IBOutlet NSPopUpButton *avrdudeConfigPopUpButton;
}
- (IBAction)showPrefs:(id)sender;
- (IBAction)browseAvrdude:(id)sender;
- (IBAction)closePrefs:(id)sender;

- (IBAction)deviceChanged:(id)sender;

- (IBAction)eraseDevice:(id)sender;

- (IBAction)browseFlash:(id)sender;
- (IBAction)programFlash:(id)sender;
- (IBAction)verifyFlash:(id)sender;
- (IBAction)readFlash:(id)sender;


- (IBAction)browseEeprom:(id)sender;
- (IBAction)programEeprom:(id)sender;
- (IBAction)verifyEeprom:(id)sender;
- (IBAction)readEeprom:(id)sender;

- (IBAction)programFuses:(id)sender;
- (IBAction)readFuses:(id)sender;
- (IBAction)verifyFuses:(id)sender;
@end
