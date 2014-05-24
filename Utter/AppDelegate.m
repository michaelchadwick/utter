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

@synthesize parentWindow;
@synthesize textToUtter;
@synthesize voicesPopup;
@synthesize opsDrawer;
@synthesize opsDrawerToggle;
@synthesize opsSpeedCheck;
@synthesize opsSpeedSlider;
@synthesize opsPitchCheck;
@synthesize opsPitchSlider;
@synthesize opsVolumeSlider;
@synthesize opsSaveToFileCheck;
@synthesize opsUseTextAsFileName;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  spSynth = [[NSSpeechSynthesizer alloc] init];

  [spSynth setDelegate:self];
  [opsDrawer setDelegate:self];
  [textToUtter setDelegate:self];

  [textToUtter setStringValue:@"hello world"];
  [opsVolumeSlider setFloatValue:1.0];

  [self populateVoices];
  [self setupOptionsDrawer];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
  NSString *curVoice = [NSString stringWithFormat:@"%@%@", APPLE_VOICE_PREFIX, [voicesPopup titleOfSelectedItem]];
  NSString *utterance = [textToUtter stringValue];

  // set voice
  [spSynth setVoice:curVoice];
  NSLog(@"utteranceVOICE: %@", [spSynth voice]);

  // set rate/speed
  if ([opsSpeedCheck state] == NSOnState)
  {
    [spSynth setRate:[opsSpeedSlider floatValue]];
  }
  NSLog(@"utteranceRATE: %f", [spSynth rate]);

  // set pitch
  if ([opsPitchCheck state] == NSOnState)
  {
//    [spSynth setObject:opsPitchSlider forProperty:NSSpeechPitchBaseProperty error:Nil];
//    [spSynth setObject:opsPitchSlider forProperty:NSSpeechPitchModProperty error:Nil];
  }
  NSLog(@"utterancePITCHBASE: %@", [spSynth objectForProperty:NSSpeechPitchBaseProperty error:Nil]);
  NSLog(@"utterancePITCHMOD: %@", [spSynth objectForProperty:NSSpeechPitchModProperty error:Nil]);

  // set volume
  [spSynth setVolume:[opsVolumeSlider floatValue]];
  NSLog(@"utteranceVOLUME: %f", [spSynth volume]);

  // speak
  [spSynth stopSpeaking];
  bool speechPlayed = [spSynth startSpeakingString:utterance];
  NSLog(@"speech sent to speakers successfully? %d", speechPlayed);

  // save to file, if enabled
  if ([opsSaveToFileCheck state] == NSOnState)
  {
    NSSpeechSynthesizer *spSynthToSave = [[NSSpeechSynthesizer alloc] init];
    [spSynthToSave setDelegate:self];
    NSString *utteranceToSave = [textToUtter stringValue];
    [spSynthToSave setVoice:curVoice];
    if ([opsSpeedCheck state] == NSOnState)
      [spSynthToSave setRate:[opsSpeedSlider floatValue]];
    if ([opsPitchCheck state] == NSOnState)
    {
      //    [spSynth setObject:opsPitchSlider forProperty:NSSpeechPitchBaseProperty error:Nil];
      //    [spSynth setObject:opsPitchSlider forProperty:NSSpeechPitchModProperty error:Nil];
    }
    [spSynthToSave setVolume:[opsVolumeSlider floatValue]];

    NSString *homeUrl = [[[NSProcessInfo processInfo] environment] objectForKey:@"HOME"];
    NSString *fileString;

    if ([opsUseTextAsFileName state] == NSOffState)
    {
      int fileCode = arc4random_uniform(999999999);
      fileString = [NSString stringWithFormat:@"%@/Desktop/utter_%d.aiff", homeUrl, fileCode];
    } else {
      NSString *customName = [textToUtter stringValue];
      fileString = [NSString stringWithFormat:@"%@/Desktop/utter_%@.aiff", homeUrl, customName];
    }
    NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:fileString];
    NSLog(@"fileUrl: %@", fileUrl);
    bool speechSaved = [spSynthToSave startSpeakingString:utteranceToSave toURL:fileUrl];
    NSLog(@"speech sent to file successfully? %d", speechSaved);
  }
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking {}

- (void)setupOptionsDrawer
{
  [opsDrawer setPreferredEdge:NSMinYEdge];
  [opsDrawer setMinContentSize:NSMakeSize(100,150)];
  [opsDrawer setMaxContentSize:NSMakeSize(100,150)];
  [opsDrawer setLeadingOffset:20];
  [opsDrawer setTrailingOffset:20];
}

- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize
{
  return contentSize;
}

- (void)opsDrawerDidToggle:(id)sender
{
  NSDrawerState state = [opsDrawer state];
  if (NSDrawerOpeningState == state || NSDrawerOpenState == state) {
    [opsDrawer close];
  } else {
    [opsDrawer openOnEdge:NSMinYEdge];
  }
}

- (IBAction)opsSpeedDidToggle:(id)sender {}
- (IBAction)opsSpeedDidChange:(id)sender {}
- (IBAction)opsPitchDidToggle:(id)sender {}
- (IBAction)opsPitchDidChange:(id)sender {}
- (IBAction)opsVolumeDidChange:(id)sender {}
- (IBAction)opsSaveToFileDidToggle:(id)sender {
  if ([opsSaveToFileCheck state] == NSOnState)
  {
    [opsUseTextAsFileName setEnabled:true];
  } else {
    [opsUseTextAsFileName setEnabled:false];
    [opsUseTextAsFileName setState:0];
  }
}
- (IBAction)opsUseTextAsFileNameDidToggle:(id)sender {}

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
