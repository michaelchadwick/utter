//
//  AppDelegate.m
//  Utter
//
//  Created by Michael Chadwick on 5/17/14.
//  Copyright (c) 2014 Codana.me. All rights reserved.
//

#import "AppDelegate.h"
#import "UtterConstants.h"

@implementation AppDelegate

@synthesize textToUtter;
@synthesize opsDrawer;
@synthesize voicesPopup;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  [opsDrawer setDelegate:self];
  [textToUtter setDelegate:self];

  [self populateVoices];
  [self setupOptionsDrawer];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
  spSynth = [[NSSpeechSynthesizer alloc] init];
  NSString *curVoice = [NSString stringWithFormat:@"%@%@", APPLE_VOICE_PREFIX, [voicesPopup titleOfSelectedItem]];
  [spSynth setVoice:curVoice];

  NSString *utterance = [textToUtter stringValue];
  [spSynth startSpeakingString:utterance];
}

- (void)setupOptionsDrawer
{
  [opsDrawer setPreferredEdge:NSMinYEdge];
  NSSize contentSize = NSMakeSize(100,100);

  [opsDrawer setMinContentSize:contentSize];
  [opsDrawer setMaxContentSize:NSMakeSize(400,400)];
  [opsDrawer setContentSize:NSMakeSize(400,400)];
}

- (void)toggleOptionsDrawer:(id)sender
{
  NSDrawerState state = [opsDrawer state];
  if (NSDrawerOpeningState == state || NSDrawerOpenState == state) {
    [opsDrawer close];
  } else {
    [opsDrawer openOnEdge:NSMinYEdge];
  }
}

- (void)drawerWillOpen:(NSNotification *)notification {}
- (void)drawerWillClose:(NSNotification *)notification {}

- (void)populateVoices
{
  NSArray *voiceNames = [NSSpeechSynthesizer availableVoices];
  for (NSString *voiceFullName in voiceNames)
  {
    NSString *voiceBaseName;
    voiceBaseName = [voiceFullName substringFromIndex:[voiceFullName rangeOfString:@"." options:NSBackwardsSearch].location+1];
    [voicesPopup addItemWithTitle:voiceBaseName];
  }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
  return YES;
}

@end
