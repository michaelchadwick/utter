//
//  AppDelegate.h
//  Utter
//
//  Created by Michael Chadwick on 5/17/14.
//  Copyright (c) 2014 Codana.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTextFieldDelegate, NSDrawerDelegate> {
  NSSpeechSynthesizer *spSynth;
}

@property (assign) IBOutlet NSWindow *parentWindow;
@property (weak) IBOutlet NSTextField *textToUtter;
@property (weak) IBOutlet NSPopUpButton *voicesPopup;
@property (weak) IBOutlet NSButton *opsDrawerToggle;

@property (weak) IBOutlet NSDrawer *opsDrawer;
@property (weak) IBOutlet NSButton *opsSpeedCheck;
@property (weak) IBOutlet NSSlider *opsSpeed;
@property (weak) IBOutlet NSButton *opsPitchCheck;
@property (weak) IBOutlet NSSlider *opsPitch;
@property (weak) IBOutlet NSSlider *opsVolume;
@property (weak) IBOutlet NSButton *opsSaveToFileCheck;


- (IBAction)toggleOptionsDrawer:(id)sender;

@end
