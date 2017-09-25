/* AVRFusesWindowController */

#import <Cocoa/Cocoa.h>

@interface AVRFusesWindowController : NSObject
{
    IBOutlet NSPopUpButton *devicePopUpButton;
    IBOutlet NSTableView *fusesTableView;
    IBOutlet NSTextView *logTextView;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSWindow *prefsWindow;
    IBOutlet NSWindow *projectWindow;
    IBOutlet NSTabView *tabView;
	IBOutlet NSTextField *avrdudeTextField;
	IBOutlet NSPopUpButton *avrdudeConfigPopUpButton;
	IBOutlet NSPopUpButton *avrdudeSerialBaudPopUpButton;
	IBOutlet NSComboBox *avrdudePortPopUpButton;
    IBOutlet NSTextField *avrdudeBitClockTextField;
	
	IBOutlet NSTableView *lockbitsTableView;
    
    IBOutlet NSTextField *lfuseText;
    IBOutlet NSTextField *hfuseText;
    IBOutlet NSTextField *efuseText;
    IBOutlet NSTextField *lfuseTextLabel;
    IBOutlet NSTextField *hfuseTextLabel;
    IBOutlet NSTextField *efuseTextLabel;
    
    IBOutlet NSPopUpButton *projectDevicePopUpButton;
    IBOutlet NSTextField *projectNameTextField;
    IBOutlet NSTextField *projectFlashTextField;
    IBOutlet NSTextField *projectEepromTextField;
    IBOutlet NSTextField *projectLowFuseTextField;
    IBOutlet NSTextField *projectHighFuseTextField;
    IBOutlet NSTextField *projectExtFuseTextField;
    IBOutlet NSTextField *projectLowFuseTextLabel;
    IBOutlet NSTextField *projectHighFuseTextLabel;
    IBOutlet NSTextField *projectExtFuseTextLabel;
    IBOutlet NSButtonCell *projectOkButton;
    IBOutlet NSButton *projectDeleteButton;
    
    IBOutlet NSMenu *projectsMenu;
    IBOutlet NSMenu *projectsEditMenu;
}
- (IBAction)showPrefs:(id)sender;
- (IBAction)browseAvrdude:(id)sender;
- (IBAction)avrdudeChanged: (id) sender;
- (IBAction)closePrefs:(id)sender;

- (IBAction)deviceChanged:(id)sender;

- (IBAction)eraseDevice:(id)sender;

- (IBAction)autodetectDevice:(id)sender;

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

- (IBAction)programLockbits:(id)sender;
- (IBAction)readLockbits:(id)sender;
- (IBAction)verifyLockbits:(id)sender;

- (IBAction)lfuseTextUpdated:(id)sender;
- (IBAction)hfuseTextUpdated:(id)sender;
- (IBAction)efuseTextUpdated:(id)sender;

- (IBAction)clearLog:(id)sender;
- (IBAction)copyLog:(id)sender;

- (IBAction)newProject:(id)sender;
- (IBAction)closeProjectDialog:(id)sender;
- (IBAction)saveProject:(id)sender;
- (IBAction)deleteProject:(id)sender;
- (IBAction)openProject: (id)sender;
- (IBAction)editProject: (id)sender;
- (IBAction)projectBrowseFlash:(id)sender;
- (IBAction)projectBrowseEeprom:(id)sender;
@end
