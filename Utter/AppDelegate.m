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
@synthesize opsPitchCheck;
@synthesize opsPitchSlider;
@synthesize opsVolumeSlider;
@synthesize opsSaveToFileCheck;
@synthesize opsUseTextAsFileNameCheck;

#pragma mark - Main Setup Event
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
  synth = [[NSSpeechSynthesizer alloc] init];

  [synth setDelegate:self];
  [opsDrawer setDelegate:self];
  [textToUtter setDelegate:self];

  [textToUtter setStringValue:UTTERANCE_INITIAL];

  [self setupBooleans];
  [self populateVoices];
  [self setupOptionsDrawer];
}

#pragma mark - Setup Subroutines
- (void)setupBooleans {
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

#pragma mark - Speech Interaction Subroutines
- (void)startStopUtterance {
  // utterance being spoken
  if (isSpeaking)
  {
    [self stopUtterance];
  }
  // utterance not currently speaking
  else
  {
    [self startUtterance];
  }
}
- (void)startUtterance {
  NSString *curVoice = [NSString stringWithFormat:@"%@%@", APPLE_VOICE_PREFIX, [voicesPopup titleOfSelectedItem]];
  NSString *utterance = [textToUtter stringValue];

  // set voice
  [synth setVoice:curVoice];

  // set rate/speed
  if ([opsSpeedCheck state] == NSOnState)
  {
    [synth setRate:[opsSpeedSlider floatValue]];
  }

  // set pitch
  if ([opsPitchCheck state] == NSOnState)
  {
    [synth setObject:[NSNumber numberWithFloat:[opsPitchSlider floatValue]] forProperty:NSSpeechPitchBaseProperty error:Nil];
  }

  // set volume
  [synth setVolume:[opsVolumeSlider floatValue]];

  // speak!
  [synth stopSpeaking];
  [synth startSpeakingString:utterance];
  [btnPlayStop setTitle:@"O"];
  [btnPauseResume setEnabled:YES];
  isSpeaking = YES;
  NSLog(@"utterance is speaking");

  [self logSpeechStats];

  // save to file, if enabled
  if ([opsSaveToFileCheck state] == NSOnState)
  {
    [self saveUtteranceToFile];
  }

}
- (void)stopUtterance {
  [synth stopSpeaking];
  [btnPlayStop setTitle:@">"];
  [btnPauseResume setEnabled:NO];
  isSpeaking = NO;
  NSLog(@"utterance stopped");
}
- (void)pauseResumeUtterance {
  if (isPaused)
  {
    [self resumeUtterance];
  }
  else
  {
    [self pauseUtterance];
  }
}
- (void)pauseUtterance {
  [synth pauseSpeakingAtBoundary:NSSpeechImmediateBoundary];
  [btnPauseResume setTitle:@"|>"];
  [btnPlayStop setEnabled:NO];
  isPaused = YES;
  isSpeaking = NO;
  NSLog(@"utterance paused");
}
- (void)resumeUtterance {
  [synth continueSpeaking];
  [btnPauseResume setTitle:@"||"];
  [btnPlayStop setEnabled:YES];
  isPaused = NO;
  isSpeaking = YES;
  NSLog(@"utterance resumed; playing");

  [self logSpeechStats];
}
- (void)saveUtteranceToFile {
  NSSpeechSynthesizer *synthToSave = [[NSSpeechSynthesizer alloc] init];
  [synthToSave setDelegate:self];
  NSString *utteranceToSave = [textToUtter stringValue];
  NSString *curVoice = [NSString stringWithFormat:@"%@%@", APPLE_VOICE_PREFIX, [voicesPopup titleOfSelectedItem]];
  [synthToSave setVoice:curVoice];
  if ([opsSpeedCheck state] == NSOnState)
    [synthToSave setRate:[opsSpeedSlider floatValue]];
  if ([opsPitchCheck state] == NSOnState)
  {
    [synth setObject:opsPitchSlider forProperty:NSSpeechPitchBaseProperty error:Nil];
    [synth setObject:opsPitchSlider forProperty:NSSpeechPitchModProperty error:Nil];
  }
  [synthToSave setVolume:[opsVolumeSlider floatValue]];

  NSString *homeUrl = [[[NSProcessInfo processInfo] environment] objectForKey:@"HOME"];
  NSString *fileString;

  if ([opsUseTextAsFileNameCheck state] == NSOffState)
  {
    int fileCode = arc4random_uniform(999999999);
    fileString = [NSString stringWithFormat:@"%@/Desktop/utter_%d.aiff", homeUrl, fileCode];
  } else {
    NSString *customName = [textToUtter stringValue];
    fileString = [NSString stringWithFormat:@"%@/Desktop/utter_%@.aiff", homeUrl, customName];
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
  //NSLog(@"utterancePITCHMOD: %@", [synth objectForProperty:NSSpeechPitchModProperty error:Nil]);
  NSLog(@"utteranceVOLUME: %f", [synth volume]);
}

#pragma mark - IBActions
- (IBAction)btnStartStopClick:(id)sender { [self startStopUtterance]; }
- (IBAction)btnPauseResumeClick:(id)sender { [self pauseResumeUtterance]; }

- (IBAction)opsDrawerDidToggle:(id)sender {
  NSDrawerState state = [opsDrawer state];
  if (NSDrawerOpeningState == state || NSDrawerOpenState == state) {
    [opsDrawer close];
  } else {
    [opsDrawer openOnEdge:NSMinYEdge];
  }
}

- (IBAction)opsSpeedDidToggle:(id)sender {
  NSLog(@"speedRateCheck toggled to: %ld", (long)[opsSpeedCheck state]);
}
- (IBAction)opsSpeedDidChange:(id)sender {
  if ([opsSpeedCheck state] == NSOnState)
  {
    NSLog(@"opsSpeedSlider changed to: %ld", (long)[opsSpeedSlider floatValue]);

    if (!isPaused) { [self startStopUtterance]; }

    [synth setRate:[opsSpeedSlider floatValue]];
    //[synth setObject:[opsSpeedSlider value] forProperty:NSSpeechRateProperty error:nil];
    NSLog(@"synth rate/speed changed to: %@", [synth objectForProperty:NSSpeechRateProperty error:nil]);

    if (!isPaused) { [self startUtterance]; }
  }
}

- (IBAction)opsPitchDidToggle:(id)sender {
  NSLog(@"pitchCheck toggled to: %ld", (long)[opsPitchCheck state]);
}
- (IBAction)opsPitchDidChange:(id)sender {
  if ([opsPitchCheck state] == NSOnState)
  {
    NSLog(@"opsPitchSlider changed to: %ld", (long)[opsPitchSlider floatValue]);

    if (!isPaused) { [self startStopUtterance]; }

    NSNumber *newPitch = [NSNumber numberWithFloat:[opsPitchSlider floatValue]];

    [synth setObject:newPitch forProperty:NSSpeechPitchBaseProperty error:nil];
    NSLog(@"synth pitch base: %@", [synth objectForProperty:NSSpeechPitchBaseProperty error:nil]);

    if (!isPaused) { [self startUtterance]; }
  }
}

- (IBAction)opsVolumeDidChange:(id)sender {
  NSLog(@"opsVolumeSlider changed to: %ld", (long)[opsVolumeSlider floatValue]);

  if (!isPaused) { [self startStopUtterance]; }

  [synth setVolume:[opsVolumeSlider floatValue]];
  NSLog(@"synth volume: %@", [synth objectForProperty:NSSpeechVolumeProperty error:nil]);

  if (!isPaused) { [self startUtterance]; }
}

- (IBAction)opsSaveToFileDidToggle:(id)sender {
  NSLog(@"opsSaveToFileCheck toggled to: %ld", (long)[opsSaveToFileCheck state]);
  if ([opsSaveToFileCheck state] == NSOnState)
  {
    [opsUseTextAsFileNameCheck setEnabled:true];
  } else {
    [opsUseTextAsFileNameCheck setEnabled:false];
    [opsUseTextAsFileNameCheck setState:0];
  }
}
- (IBAction)opsUseTextAsFileNameDidToggle:(id)sender {
  NSLog(@"opsUseTextAsFileNameCheck toggled to: %ld", (long)[opsUseTextAsFileNameCheck state]);
}

#pragma mark - Event Handlers
- (void)controlTextDidEndEditing:(NSNotification *)obj {
  [self startStopUtterance];
}

- (void)drawerWillOpen:(NSNotification *)notification {}
- (void)drawerWillClose:(NSNotification *)notification {}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking {
  NSLog(@"utterance finished");
  if ([synth isSpeaking] == NO)
  {
    if ([btnPauseResume isEnabled] == YES) [btnPauseResume setEnabled:NO];
    if ([btnPlayStop isEnabled] == NO) [btnPlayStop setEnabled:YES];
    [btnPlayStop setTitle:@">"];
    isSpeaking = NO;
  }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
  return YES;
}

@end
