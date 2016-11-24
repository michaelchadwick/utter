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
@synthesize opsSpeedSlider;
@synthesize opsSpeedText;
@synthesize opsSpeedReset;
@synthesize opsPitchSlider;
@synthesize opsPitchText;
@synthesize opsPitchReset;
@synthesize opsPitchModSlider;
@synthesize opsPitchModText;
@synthesize opsPitchModReset;
@synthesize opsVolumeSlider;
@synthesize opsVolumeText;
@synthesize opsVolumeReset;
@synthesize opsSaveToFileCheck;
@synthesize opsUseTextAsFileNameCheck;

-(id)init {
  self = [super init];
  return self;
}

#pragma mark - Main Setup Event
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  isDebug = false; // flag for triggering debug messages or not
  synth = [[NSSpeechSynthesizer alloc] init];

  [synth setDelegate:self];
  [opsDrawer setDelegate:self];
  [textToUtter setDelegate:self];
  [textToUtter.textStorage setDelegate:self];
  [textToUtter setFont:[NSFont userFontOfSize:14.0]];
  [textToUtter setString:INITIAL_TEXT];

  [self setupButtonIcons];
  [self setupAudioFlags];
  [self populateVoices];
  [self setupOptionsDrawer];
}
- (void)applicationWillTerminate:(NSNotification *)notification {
  [self stopUtterance];
}

#pragma mark - Setup Subroutines
- (void)setupButtonIcons {
  [btnPlayStop setTitle:ICON_PLAY];
  [btnPauseResume setTitle:ICON_PAUSE];
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
  [synth setRate:[opsSpeedSlider floatValue]];
}
- (void)setSynthPitch {
  NSNumber *newPitch = [NSNumber numberWithFloat:[opsPitchSlider floatValue]];
  [synth setObject:newPitch forProperty:NSSpeechPitchBaseProperty error:nil];
}
- (void)setSynthPitchMod {
  NSNumber *newPitchMod = [NSNumber numberWithFloat:[opsPitchModSlider floatValue]];
  [synth setObject:newPitchMod forProperty:NSSpeechPitchModProperty error:nil];
}
- (void)setSynthVolume {
  [synth setVolume:[opsVolumeSlider floatValue]/100];
}
- (void)setupAudioFlags {
  isPaused = NO;
  isSpeaking = NO;
}

#pragma mark - Speech Interaction Subroutines
- (void)startStopUtterance {
  if (isSpeaking)
    [self stopUtterance];
  else
    [self startUtterance];
}
- (void)startUtterance {
  NSString *utterance = [[textToUtter textStorage] string];

  // make sure we stop any current speaking
  [synth stopSpeaking];

  // set up attributes
  [self setSynthVoice];
  [self setSynthSpeed];
  [self setSynthPitch];
  [self setSynthPitchMod];
  [self setSynthVolume];

  // speak!
  [btnPlayStop setTitle:ICON_STOP];
  [btnPauseResume setEnabled:YES];
  [synth startSpeakingString:utterance];
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
  [self logDebug:@"|| utterance PAUSED"];
  [synth pauseSpeakingAtBoundary:NSSpeechImmediateBoundary];
  [btnPauseResume setTitle:ICON_RESUME];
  [btnPlayStop setEnabled:NO];
  isPaused = YES;
  isSpeaking = NO;
}
- (void)resumeUtterance {
  [self logDebug: @"|> utterance RESUMED"];
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
  NSString *utteranceToSave = [[textToUtter textStorage] string];
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
    NSString *customName = [[textToUtter textStorage] string];
    fileString = [NSString stringWithFormat:@"%@/Desktop/%@.aiff", homeUrl, customName];
  }
  NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:fileString];
  [self logDebug:[NSString stringWithFormat:@"fileUrl: %@", fileUrl]];
  bool speechSaved = [synthToSave startSpeakingString:utteranceToSave toURL:fileUrl];
  [self logDebug:[NSString stringWithFormat:@"utterance sent to file successfully? %d", speechSaved]];
}

#pragma mark - Helper Methods
- (void)logSpeechStats {
  if (isDebug) {
    NSString *curVoice = [synth voice];
    NSUInteger rangeIndex = [curVoice rangeOfString:@"." options:NSBackwardsSearch].location+1;
    NSUInteger rangeLength = curVoice.length - rangeIndex;
    NSRange range = NSMakeRange(rangeIndex, rangeLength);
    NSLog(@"---------------------");
    NSLog(@"!!! utterance STARTED");
    NSLog(@"utteranceVOICE: %@", [curVoice substringWithRange:range]);
    NSLog(@"utteranceRATE: %f", [synth rate]);
    NSLog(@"utterancePITCHBASE: %@", [synth objectForProperty:NSSpeechPitchBaseProperty error:Nil]);
    NSLog(@"utterancePITCHMOD: %@", [synth objectForProperty:NSSpeechPitchModProperty error:Nil]);
    NSLog(@"utteranceVOLUME: %f", [synth volume]);
  }
}
- (void)logDebug:(NSString *)msg {
  if (isDebug) {
    NSLog(@"%@", msg);
  }
}

#pragma mark - IBActions
- (IBAction)btnStartStopClick:(id)sender {
  [self startStopUtterance];
}
- (IBAction)btnPauseResumeClick:(id)sender {
  [self pauseResumeUtterance];
}
- (IBAction)voicesPopupDidChange:(id)sender {
  if (isSpeaking) {
    [self logDebug:@"Utter is currently speaking, so doing a stopUtterance"];
    [self stopUtterance];
    [self startUtterance];
  } else {
    [self startUtterance];
  }
}

- (IBAction)opsDrawerDidToggle:(id)sender {
  NSDrawerState state = [opsDrawer state];
  if (NSDrawerOpeningState == state || NSDrawerOpenState == state) {
    [opsDrawer close];
  } else {
    [opsDrawer openOnEdge:NSMinYEdge];
  }
}

- (IBAction)opsSpeedDidChange:(id)sender {
  [opsSpeedText setFloatValue:(long)[opsSpeedSlider floatValue]];
  [self setSynthSpeed];
  if (!isPaused) { [self startUtterance]; }
}
- (IBAction)opsPitchDidChange:(id)sender {
  [opsPitchText setFloatValue:(long)[opsPitchSlider floatValue]];
  [self setSynthPitch];
  if (!isPaused) { [self startUtterance]; }
}
- (IBAction)opsPitchModDidChange:(id)sender {
  [opsPitchModText setFloatValue:(long)[opsPitchModSlider floatValue]];
  [self setSynthPitchMod];
  if (!isPaused) { [self startUtterance]; }
}
- (IBAction)opsVolumeDidChange:(id)sender {
  [opsVolumeText setIntegerValue:(long)[opsVolumeSlider integerValue]];
  [self setSynthVolume];
  if (!isPaused) { [self startUtterance]; }
}

- (IBAction)opsSpeedResetClick:(id)sender {
  [opsSpeedSlider setFloatValue:INITIAL_SPEED];
  [opsSpeedText setFloatValue:INITIAL_SPEED];

  [self startStopUtterance];
  [self startUtterance];
}
- (IBAction)opsPitchResetClick:(id)sender {
  [opsPitchSlider setFloatValue:INITIAL_PITCH];
  [opsPitchText setFloatValue:INITIAL_PITCH];

  [self startStopUtterance];
  [self startUtterance];
}
- (IBAction)opsPitchModResetClick:(id)sender {
  [opsPitchModSlider setFloatValue:INITIAL_PITCHMOD];
  [opsPitchModText setFloatValue:INITIAL_PITCHMOD];

  [self startStopUtterance];
  [self startUtterance];
}
- (IBAction)opsVolumeResetClick:(id)sender {
  [opsVolumeSlider setIntegerValue:INITIAL_VOLUME];
  [opsVolumeText setIntegerValue:INITIAL_VOLUME];

  [self startStopUtterance];
  [self startUtterance];
}

- (IBAction)opsSaveToFileDidToggle:(id)sender {
  [self logDebug:[NSString stringWithFormat:@"opsSaveToFileCheck toggled to: %ld", (long)[opsSaveToFileCheck state]]];
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
  [self logDebug:[NSString stringWithFormat:@"opsUseTextAsFileNameCheck toggled to: %ld", (long)[opsUseTextAsFileNameCheck state]]];
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
- (void)textStorageDidProcessEditing:(NSNotification *)notification {
  NSUInteger flags = [[NSApp currentEvent] modifierFlags];
  if (flags & NSShiftKeyMask) {
    [self startStopUtterance];
    //[self logDebug:@"textStorageWillProcessEditing and CommandKey"];
  }
}

- (void)drawerWillOpen:(NSNotification *)notification {
}
- (void)drawerWillClose:(NSNotification *)notification {
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking {
  [self logDebug:@"XXX utterance FINISHED"];
  [btnPlayStop setTitle:ICON_PLAY];
  [btnPauseResume setEnabled:NO];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
  return YES;
}

@end
