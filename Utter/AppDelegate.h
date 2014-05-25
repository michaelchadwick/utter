//
//  AppDelegate.h
//  Utter
//
//  Created by Michael Chadwick on 5/17/14.
//  Copyright (c) 2014 Codana.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTextFieldDelegate, NSDrawerDelegate, NSSpeechSynthesizerDelegate> {
  NSSpeechSynthesizer *synth;
  NSString *initialUtterance;
  bool isPaused;
  bool isSpeaking;
}

@property (assign) IBOutlet NSWindow *parentWindow;
@property (weak) IBOutlet NSTextField *textToUtter;
@property (weak) IBOutlet NSButton *btnPlayStop;
@property (weak) IBOutlet NSButton *btnPauseResume;

@property (weak) IBOutlet NSPopUpButton *voicesPopup;
@property (weak) IBOutlet NSButton *opsDrawerToggle;

@property (weak) IBOutlet NSDrawer *opsDrawer;
@property (weak) IBOutlet NSButton *opsSpeedCheck;
@property (weak) IBOutlet NSSlider *opsSpeedSlider;
@property (weak) IBOutlet NSButton *opsPitchCheck;
@property (weak) IBOutlet NSSlider *opsPitchSlider;
@property (weak) IBOutlet NSSlider *opsVolumeSlider;
@property (weak) IBOutlet NSButton *opsSaveToFileCheck;
@property (weak) IBOutlet NSButton *opsUseTextAsFileNameCheck;

- (IBAction)btnStartStopClick:(id)sender;
- (IBAction)btnPauseResumeClick:(id)sender;

- (IBAction)opsDrawerDidToggle:(id)sender;

- (IBAction)opsSpeedDidToggle:(id)sender;
- (IBAction)opsSpeedDidChange:(id)sender;

- (IBAction)opsPitchDidToggle:(id)sender;
- (IBAction)opsPitchDidChange:(id)sender;

- (IBAction)opsVolumeDidChange:(id)sender;

- (IBAction)opsSaveToFileDidToggle:(id)sender;
- (IBAction)opsUseTextAsFileNameDidToggle:(id)sender;

@end
