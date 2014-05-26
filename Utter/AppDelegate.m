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

#pragma mark - Synthesis
@synthesize parentWindow;
@synthesize textToUtter;
@synthesize btnPlayStop;
@synthesize btnPauseResume;
@synthesize voicesPopup;
@synthesize opsDrawer;
@synthesize opsDrawerToggle;
@synthesize opsSpeedCheck;
@synthesize opsSpeedSlider;
@synthesize opsSpeedText;
@synthesize opsSpeedReset;
@synthesize opsPitchCheck;
@synthesize opsPitchSlider;
@synthesize opsPitchText;
@synthesize opsPitchReset;
@synthesize opsPitchModCheck;
@synthesize opsPitchModSlider;
@synthesize opsPitchModText;
@synthesize opsPitchModReset;
@synthesize opsVolumeCheck;
@synthesize opsVolumeSlider;
@synthesize opsVolumeText;
@synthesize opsVolumeReset;
@synthesize opsSaveToFileCheck;
@synthesize opsUseTextAsFileNameCheck;

#pragma mark - Main Setup Event
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  synth = [[NSSpeechSynthesizer alloc] init];

  [synth setDelegate:self];
  [opsDrawer setDelegate:self];
  [textToUtter setDelegate:self];

  [textToUtter setStringValue:INITIAL_TEXT];

  [self setupButtonIcons];
  [self setupAudioFlags];
  [self populateVoices];
  [self setupOptionsDrawer];
}

#pragma mark - Setup Subroutines
- (void)setupButtonIcons
{
  [btnPlayStop setTitle:ICON_PLAY];
  [btnPauseResume setTitle:ICON_PAUSE];
}
- (void)setupAudioFlags {
  isPaused = NO;
  isSpeaking = NO;
}
- (void)populateVoices {
  NSArray *voiceNames = [NSSpeechSynthesizer availableVoices];
  for (NSString *voiceFullName in voiceNames)
  {
    NSString *voiceBaseName;
    voiceBaseName = [voiceFullName substringFromIndex:[voiceFullName rangeOfString:@"." options:NSBackwardsSearch].location+1];
    [voicesPopup addItemWithTitle:voiceBaseName];
  }
}
- (void)setupOptionsDrawer {
  [opsDrawer setPreferredEdge:NSMinYEdge];
  [opsDrawer setMinContentSize:NSMakeSize(100,150)];
  [opsDrawer setMaxContentSize:NSMakeSize(100,150)];
  [opsDrawer setLeadingOffset:20];
  [opsDrawer setTrailingOffset:20];
}
- (void)setSynthVoice {
  NSString *curVoice = [NSString stringWithFormat:@"%@%@", APPLE_VOICE_PREFIX, [voicesPopup titleOfSelectedItem]];
  [synth setVoice:curVoice];
}
- (void)setSynthSpeed {
  if ([opsSpeedCheck state] == NSOnState)
    [synth setRate:[opsSpeedSlider floatValue]];
}
- (void)setSynthPitch {
  if ([opsPitchCheck state] == NSOnState)
  {
    NSNumber *newPitch = [NSNumber numberWithFloat:[opsPitchSlider floatValue]];
    [synth setObject:newPitch forProperty:NSSpeechPitchBaseProperty error:nil];
  }
}
- (void)setSynthPitchMod {
  if ([opsPitchModCheck state] == NSOnState)
  {
    NSNumber *newPitchMod = [NSNumber numberWithFloat:[opsPitchModSlider floatValue]];
    [synth setObject:newPitchMod forProperty:NSSpeechPitchModProperty error:nil];
  }
}
- (void)setSynthVolume {
  if ([opsVolumeCheck state] == NSOnState)
    [synth setVolume:[opsVolumeSlider floatValue]/100];
}

#pragma mark - Speech Interaction Subroutines
- (void)startStopUtterance {
  if (isSpeaking)
    [self stopUtterance];
  else
    [self startUtterance];
}
- (void)startUtterance {
  NSString *utterance = [textToUtter stringValue];

  // set up attributes
  [self setSynthVoice];
  [self setSynthSpeed];
  [self setSynthPitch];
  [self setSynthPitchMod];
  [self setSynthVolume];

  // speak!
  [synth stopSpeaking];
  [synth startSpeakingString:utterance];
  [btnPlayStop setTitle:ICON_STOP];
  [btnPauseResume setEnabled:YES];
  isSpeaking = YES;

  [self logSpeechStats];

  // save to file, if enabled
  if ([opsSaveToFileCheck state] == NSOnState)
    [self saveUtteranceToFile];
}
- (void)stopUtterance {
  [synth stopSpeaking];
  [btnPlayStop setTitle:ICON_PLAY];
  [btnPauseResume setEnabled:NO];
  isSpeaking = NO;
}
- (void)pauseResumeUtterance {
  if (isPaused)
    [self resumeUtterance];
  else
    [self pauseUtterance];
}
- (void)pauseUtterance {
  [synth pauseSpeakingAtBoundary:NSSpeechImmediateBoundary];
  [btnPauseResume setTitle:ICON_RESUME];
  [btnPlayStop setEnabled:NO];
  isPaused = YES;
  isSpeaking = NO;
}
- (void)resumeUtterance {
  [synth continueSpeaking];
  [btnPauseResume setTitle:ICON_PAUSE];
  [btnPlayStop setEnabled:YES];
  isPaused = NO;
  isSpeaking = YES;

  [self logSpeechStats];
}
- (void)saveUtteranceToFile {
  NSSpeechSynthesizer *synthToSave = [[NSSpeechSynthesizer alloc] init];
  [synthToSave setDelegate:self];
  NSString *utteranceToSave = [textToUtter stringValue];
  NSString *curVoice = [NSString stringWithFormat:@"%@%@", APPLE_VOICE_PREFIX, [voicesPopup titleOfSelectedItem]];
  [synthToSave setVoice:curVoice];
  [synthToSave setRate:[opsSpeedSlider floatValue]];
  NSNumber *newPitch = [NSNumber numberWithFloat:[opsPitchSlider floatValue]];
  [synthToSave setObject:newPitch forProperty:NSSpeechPitchBaseProperty error:nil];
  NSNumber *newPitchMod = [NSNumber numberWithFloat:[opsPitchModSlider floatValue]];
  [synthToSave setObject:newPitchMod forProperty:NSSpeechPitchModProperty error:nil];
  [synthToSave setVolume:[opsVolumeSlider floatValue]/100];

  NSString *homeUrl = [[[NSProcessInfo processInfo] environment] objectForKey:@"HOME"];
  NSString *fileString;

  if ([opsUseTextAsFileNameCheck state] == NSOffState)
  {
    int fileCode = arc4random_uniform(999999999);
    fileString = [NSString stringWithFormat:@"%@/Desktop/utter_%d.aiff", homeUrl, fileCode];
  } else {
    NSString *customName = [textToUtter stringValue];
    fileString = [NSString stringWithFormat:@"%@/Desktop/%@.aiff", homeUrl, customName];
  }
  NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:fileString];
  NSLog(@"fileUrl: %@", fileUrl);
  bool speechSaved = [synthToSave startSpeakingString:utteranceToSave toURL:fileUrl];
  NSLog(@"utterance sent to file successfully? %d", speechSaved);
}
- (void)logSpeechStats {
  NSString *curVoice = [synth voice];
  NSUInteger rangeIndex = [curVoice rangeOfString:@"." options:NSBackwardsSearch].location+1;
  NSUInteger rangeLength = curVoice.length - rangeIndex;
  NSRange range = NSMakeRange(rangeIndex, rangeLength);
  NSLog(@"utteranceVOICE: %@", [curVoice substringWithRange:range]);
  NSLog(@"utteranceRATE: %f", [synth rate]);
  NSLog(@"utterancePITCHBASE: %@", [synth objectForProperty:NSSpeechPitchBaseProperty error:Nil]);
  NSLog(@"utterancePITCHMOD: %@", [synth objectForProperty:NSSpeechPitchModProperty error:Nil]);
  NSLog(@"utteranceVOLUME: %f", [synth volume]);
}

#pragma mark - IBActions
- (IBAction)btnStartStopClick:(id)sender { [self startStopUtterance]; }
- (IBAction)btnPauseResumeClick:(id)sender { [self pauseResumeUtterance]; }
- (IBAction)voicesPopupDidChange:(id)sender {
}

- (IBAction)opsDrawerDidToggle:(id)sender {
  NSDrawerState state = [opsDrawer state];
  if (NSDrawerOpeningState == state || NSDrawerOpenState == state)
    [opsDrawer close];
  else
    [opsDrawer openOnEdge:NSMinYEdge];
}

- (IBAction)opsSpeedDidChange:(id)sender {
  [opsSpeedText setFloatValue:(long)[opsSpeedSlider floatValue]];

  if ([opsSpeedCheck state] == NSOnState)
  {
    if (!isPaused) { [self startStopUtterance]; }
    [self setSynthSpeed];
    if (!isPaused) { [self startUtterance]; }
  }
}
- (IBAction)opsPitchDidChange:(id)sender {
  [opsPitchText setFloatValue:(long)[opsPitchSlider floatValue]];

  if ([opsPitchCheck state] == NSOnState)
  {
    if (!isPaused) { [self startStopUtterance]; }
    [self setSynthPitch];
    if (!isPaused) { [self startUtterance]; }
  }
}
- (IBAction)opsPitchModDidChange:(id)sender {
  [opsPitchModText setFloatValue:(long)[opsPitchModSlider floatValue]];

  if ([opsPitchModCheck state] == NSOnState)
  {
    if (!isPaused) { [self startStopUtterance]; }
    [self setSynthPitchMod];
    if (!isPaused) { [self startUtterance]; }
  }
}
- (IBAction)opsVolumeDidChange:(id)sender {
  [opsVolumeText setIntegerValue:(long)[opsVolumeSlider integerValue]];

  if ([opsVolumeCheck state] == NSOnState)
  {
    if (!isPaused) { [self startStopUtterance]; }
    [self setSynthVolume];
    if (!isPaused) { [self startUtterance]; }
  }
}

- (IBAction)opsSpeedResetClick:(id)sender {
  [opsSpeedSlider setFloatValue:INITIAL_SPEED];
  [opsSpeedText setFloatValue:INITIAL_SPEED];
  if ([opsSpeedCheck state] == NSOnState)
  {
    [self startStopUtterance];
    [self startUtterance];
  }
}
- (IBAction)opsPitchResetClick:(id)sender {
  [opsPitchSlider setFloatValue:INITIAL_PITCH];
  [opsPitchText setFloatValue:INITIAL_PITCH];
  if ([opsPitchCheck state] == NSOnState)
  {
    [self startStopUtterance];
    [self startUtterance];
  }
}
- (IBAction)opsPitchModResetClick:(id)sender {
  [opsPitchModSlider setFloatValue:INITIAL_PITCHMOD];
  [opsPitchModText setFloatValue:INITIAL_PITCHMOD];
  if ([opsPitchModCheck state] == NSOnState)
  {
    [self startStopUtterance];
    [self startUtterance];
  }
}
- (IBAction)opsVolumeResetClick:(id)sender {
  [opsVolumeSlider setIntegerValue:INITIAL_VOLUME];
  [opsVolumeText setIntegerValue:INITIAL_VOLUME];
  if ([opsVolumeCheck state] == NSOnState)
  {
    [self startStopUtterance];
    [self startUtterance];
  }
}

- (IBAction)opsSaveToFileDidToggle:(id)sender {
  NSLog(@"opsSaveToFileCheck toggled to: %ld", (long)[opsSaveToFileCheck state]);
  if ([opsSaveToFileCheck state] == NSOnState)
  {
    [opsUseTextAsFileNameCheck setEnabled:true];
  }
  else
  {
    [opsUseTextAsFileNameCheck setEnabled:false];
    [opsUseTextAsFileNameCheck setState:0];
  }
}
- (IBAction)opsUseTextAsFileNameDidToggle:(id)sender {
  NSLog(@"opsUseTextAsFileNameCheck toggled to: %ld", (long)[opsUseTextAsFileNameCheck state]);
}

- (IBAction)opsAllResetClick:(id)sender {
  [opsSpeedSlider setFloatValue:INITIAL_SPEED];
  [opsSpeedText setFloatValue:INITIAL_SPEED];
  [opsPitchSlider setFloatValue:INITIAL_PITCH];
  [opsPitchText setFloatValue:INITIAL_PITCH];
  [opsPitchModSlider setFloatValue:INITIAL_PITCHMOD];
  [opsPitchModText setFloatValue:INITIAL_PITCHMOD];
  [opsVolumeSlider setIntegerValue:INITIAL_VOLUME];
  [opsVolumeText setFloatValue:INITIAL_VOLUME];
  [self startStopUtterance];
  [self startUtterance];
}

#pragma mark - Event Handlers
- (void)controlTextDidEndEditing:(NSNotification *)obj {
  [self startStopUtterance];
}

- (void)drawerWillOpen:(NSNotification *)notification {
}
- (void)drawerWillClose:(NSNotification *)notification {
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking {
  NSLog(@"utterance finished");
  if ([synth isSpeaking] == NO)
  {
    if ([btnPauseResume isEnabled] == YES) [btnPauseResume setEnabled:NO];
    if ([btnPlayStop isEnabled] == NO) [btnPlayStop setEnabled:YES];
    [btnPlayStop setTitle:ICON_PLAY];
    isSpeaking = NO;
  }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
  return YES;
}

@end
