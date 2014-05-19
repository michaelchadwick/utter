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
@synthesize voicesPopup;
@synthesize opsDrawer;
@synthesize opsDrawerToggle;
@synthesize opsSpeedCheck;
@synthesize opsSpeedSlider;
@synthesize opsPitchCheck;
@synthesize opsPitchSlider;
@synthesize opsVolumeSlider;
@synthesize opsSaveToFileCheck;

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
    int fileCode = arc4random_uniform(999999999);
    NSString *homeUrl = [[[NSProcessInfo processInfo] environment] objectForKey:@"HOME"];
    NSString *fileString = [NSString stringWithFormat:@"%@/Desktop/utter_%d.aiff", homeUrl, fileCode];
    NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:fileString];
    NSLog(@"fileUrl: %@", fileUrl);
    bool speechSaved = [spSynthToSave startSpeakingString:utteranceToSave toURL:fileUrl];
    NSLog(@"speech sent to file successfully? %d", speechSaved);
  }
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
  NSLog(@"speech synthesis finished");
}

- (void)setupOptionsDrawer
{
  [opsDrawer setPreferredEdge:NSMinYEdge];
  NSSize contentSize = NSMakeSize(100,100);

  [opsDrawer setMinContentSize:contentSize];
  [opsDrawer setMaxContentSize:NSMakeSize(400,400)];
  [opsDrawer setContentSize:NSMakeSize(400,400)];
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

- (IBAction)opsSpeedDidToggle:(id)sender {
  NSLog(@"opsSpeedCheck toggled to %ld", (long)[opsSpeedCheck state]);
}
- (IBAction)opsSpeedDidChange:(id)sender {
  NSLog(@"opsSpeedSlider is now %ld", (long)[opsSpeedSlider floatValue]);
}
- (IBAction)opsPitchDidToggle:(id)sender {
  NSLog(@"opsPitchCheck toggled to %ld", (long)[opsPitchCheck state]);
}
- (IBAction)opsPitchDidChange:(id)sender {
  NSLog(@"opsPitchSlider is now %ld", (long)[opsPitchSlider floatValue]);
}
- (IBAction)opsVolumeDidChange:(id)sender {
  NSLog(@"opsVolumeSlider is now %f", [opsVolumeSlider floatValue]);
}
- (IBAction)opsSaveToFileDidToggle:(id)sender {
  NSLog(@"opsSaveToFileCheck toggled to %ld", (long)[opsSaveToFileCheck state]);
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
