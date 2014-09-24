//
//  MusicViewController.m
//

#import "MusicViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+EasyFrame.h"
#import "UIImage+AverageColor.h"
#import "UILabel+BackgroundAware.h"
#import <Social/Social.h>
#import <Twitter/Twitter.h>

@interface MusicViewController() {
    BOOL viewJustLoaded;
}

@property (nonatomic, retain) MPMusicPlayerController *musicPlayer;
@property (nonatomic, retain) NSTimer* syncProgressTimer;
@property (nonatomic, assign) NSTimeInterval songDuration;

@end

@implementation MusicViewController

@synthesize musicPlayer = _musicPlayer;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
													name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
												  object:self.musicPlayer];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
												  object:self.musicPlayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
													name:MPMusicPlayerControllerVolumeDidChangeNotification
												  object:self.musicPlayer];
    
	[self.musicPlayer endGeneratingPlaybackNotifications];
    
    
	[self.musicPlayer endGeneratingPlaybackNotifications];
    self.musicPlayer = nil;
    
    artworkImageView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupVisualStyle];
    viewJustLoaded = YES;
    
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onHideHelpButtonTUI:)];
    [helpContentView addGestureRecognizer:tapGesture];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (viewJustLoaded) {
        viewJustLoaded = NO;
        songAlbumLabelContainer.height = self.view.width;
        songAlbumLabelContainer.width = self.view.height;
        songAlbumLabelContainer.center = self.view.center;
        songAlbumLabelContainer.transform = CGAffineTransformMakeRotation(-M_PI_2);
        
        discView.layer.cornerRadius = discView.width/2.0;
        discView.layer.masksToBounds = YES;
        
        self.musicPlayer = [MPMusicPlayerController iPodMusicPlayer];
        
        [self.musicPlayer currentPlaybackTime];
        
        [circularVolumeSlider setValue:[self.musicPlayer volume]];
        [circularVolumeSlider addTarget:self action:@selector(volumeChanged:) forControlEvents:UIControlEventValueChanged];
    	
        [self updateUIGIvenPlaybackState];
        
        [self registerMediaPlayerNotifications];
        [self onMPMusicPlayerControllerNowPlayingItemDidChangeNotification:nil];
        [self loadAllSongs];
        
        MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame: mpVolumeViewParentView.bounds];
        [mpVolumeViewParentView addSubview: myVolumeView];
        
        currentSongCircularProgressView.lineWidth = currentSongCircularProgressView.width / 4.0;
        currentSongCircularProgressView.progressMode = THProgressModeFill;
        currentSongCircularProgressView.progressBackgroundMode = THProgressBackgroundModeCircumference;
        currentSongCircularProgressView.clockwise = YES;
        currentSongCircularProgressView.progressColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        currentSongCircularProgressView.progressBackgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
        
        innnerRingView.lineWidth = innnerRingView.width / 4.0;
        innnerRingView.progressMode = THProgressModeFill;
        innnerRingView.clockwise = YES;
        innnerRingView.progressColor = [UIColor colorWithWhite:1.0 alpha:0.4];
        innnerRingView.percentage = 1.0;
        
        BOOL alreadyLaunched = [[NSUserDefaults standardUserDefaults] boolForKey:@"ALREADY_LAUNCHED?"];
        if (!alreadyLaunched) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ALREADY_LAUNCHED?"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self performSelector:@selector(onShowHelpButtonTUI:) withObject:nil afterDelay:0.1];
        }
    }
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    songAlbumLabel.hidden = YES;
    songArtistAndSongTitleLabel.hidden = YES;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self setAlbumTitle:songAlbumLabel.text];
    songArtistAndSongTitleLabel.text = songArtistAndSongTitleLabel.text;
    songAlbumLabel.hidden = NO;
    songArtistAndSongTitleLabel.hidden = NO;
}

- (void) cancelSyncTimer {
    [self.syncProgressTimer invalidate];
    self.syncProgressTimer = nil;
}

- (void) restartSyncTimer {
    [self cancelSyncTimer];
    self.syncProgressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(syncProgress) userInfo:nil repeats:YES];

}

- (void) syncProgress {
    currentSongCircularProgressView.percentage = (self.musicPlayer.currentPlaybackTime / self.songDuration);
    currentSontTimeLabel.text = [self secondsToString:self.musicPlayer.currentPlaybackTime];
    currentSontTimeLabel.text = [self secondsToString:self.musicPlayer.currentPlaybackTime];
}

- (NSString*) secondsToString:(int) totalSeconds {
    int hours = totalSeconds / 60.0 / 60.0;
    int minutes = (totalSeconds % 3600) / 60;
    int seconds = totalSeconds % 60;
    
    NSString* result = @"";
    if (hours > 0) {
        result = [result stringByAppendingFormat:@"%02d:", hours];
    }
    return [result stringByAppendingFormat:@"%02d:%02d", minutes, seconds];
}

- (void) setupVisualStyle {
    [self applyParallaxEffect];
    circularVolumeSlider.maximumTrackTintColor = [UIColor colorWithWhite:0.6 alpha:0.5];
    circularVolumeSlider.minimumTrackTintColor = [UIColor whiteColor];
    circularVolumeSlider.thumbTintColor = circularVolumeSlider.minimumTrackTintColor;
}

- (void) applyParallaxEffect {
    Class class = NSClassFromString(@"UIInterpolatingMotionEffect");
    if (!class)
        return;
    
    UIMotionEffectGroup* groupEffect = nil;
    UIInterpolatingMotionEffect *interpolationHorizontal = nil;
    UIInterpolatingMotionEffect *interpolationVertical = nil;
    
    interpolationHorizontal = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    interpolationHorizontal.minimumRelativeValue = @15.0;
    interpolationHorizontal.maximumRelativeValue = @-15.0;
    
    interpolationVertical = [[UIInterpolatingMotionEffect alloc]initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    interpolationVertical.minimumRelativeValue = @15.0;
    interpolationVertical.maximumRelativeValue = @-15.0;
    
    groupEffect = [UIMotionEffectGroup new];
    groupEffect.motionEffects = @[interpolationHorizontal, interpolationVertical];
    [artworkImageView addMotionEffect:groupEffect];
    
    interpolationHorizontal = [[UIInterpolatingMotionEffect alloc]initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    interpolationHorizontal.minimumRelativeValue = @-15.0;
    interpolationHorizontal.maximumRelativeValue = @15.0;
    
    interpolationVertical = [[UIInterpolatingMotionEffect alloc]initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    interpolationVertical.minimumRelativeValue = @-15.0;
    interpolationVertical.maximumRelativeValue = @15.0;
    
    groupEffect = [UIMotionEffectGroup new];
    groupEffect.motionEffects = @[interpolationHorizontal, interpolationVertical];
    [playerView addMotionEffect:groupEffect];
}

- (void) loadAllSongs {
   [self.musicPlayer setQueueWithQuery:[MPMediaQuery albumsQuery]];
}

#pragma mark - Notifications
- (void) registerMediaPlayerNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
	[notificationCenter addObserver:self
						   selector:@selector (onMPMusicPlayerControllerNowPlayingItemDidChangeNotification:)
							   name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
							 object:self.musicPlayer];
	
	[notificationCenter addObserver:self
						   selector:@selector (onMPMusicPlayerControllerPlaybackStateDidChangeNotification:)
							   name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
							 object:self.musicPlayer];
    
    [notificationCenter addObserver:self
						   selector:@selector (onMPMusicPlayerControllerVolumeDidChangeNotification:)
							   name:MPMusicPlayerControllerVolumeDidChangeNotification
							 object:self.musicPlayer];
    
	[self.musicPlayer beginGeneratingPlaybackNotifications];
}


- (void) onMPMusicPlayerControllerNowPlayingItemDidChangeNotification:(id) notification {
   	MPMediaItem *currentItem = [self.musicPlayer nowPlayingItem];
    
    UIImage *artworkImage = nil;
	MPMediaItemArtwork *artwork = [currentItem valueForProperty:MPMediaItemPropertyArtwork];
	
	if (artwork) {
		artworkImage = [artwork imageWithSize:artworkImageView.frame.size];
	}
    
    discArtwork.image = artworkImage;
    artworkImageView.image = [self imageWithBlur:artworkImage];
    artworkColorBackground.backgroundColor = (artworkImage)?[artworkImage averageColor]:[UIColor clearColor];
    
    NSString* songTitle = [currentItem valueForProperty:MPMediaItemPropertyTitle];
    NSString* songArtist = [currentItem valueForProperty:MPMediaItemPropertyArtist];
    NSString* songAlbum = [currentItem valueForProperty:MPMediaItemPropertyAlbumTitle];

    [self setAlbumTitle:songAlbum];

    if (songTitle && songArtist) {
        songArtistAndSongTitleLabel.text = [NSString stringWithFormat:@"%@ / %@", songArtist, songTitle];
    }
    else if (songTitle) {
        songArtistAndSongTitleLabel.text = songTitle;
    }
    else if (songArtist) {
        songArtistAndSongTitleLabel.text = songArtist;
    }
    else {
        songArtistAndSongTitleLabel.text = nil;
    }
    
    if (!currentItem) {
		[self.musicPlayer stop];
        [self cancelSyncTimer];
	}

    [self reconfigureProgressTimer];
    
    if (artworkImage) {
        [songArtistAndSongTitleLabel changeTextColorToUnmatchTheBG];
        [currentSontTimeLabel changeTextColorToUnmatchTheBG];
        [songAlbumLabel changeTextColorToUnmatchTheBG];
    }
    else {
        [songArtistAndSongTitleLabel setTextColor:[UIColor whiteColor]];
        [currentSontTimeLabel setTextColor:[UIColor whiteColor]];
        [songAlbumLabel setTextColor:[UIColor whiteColor]];
    }
}

- (void) setAlbumTitle:(NSString*) songAlbum {
    songAlbumLabel.text = songAlbum;
    
    CGSize constrainedSize = CGSizeMake(songAlbumLabelContainer.height-88-10, songAlbumLabelContainer.width - 80);
    CGFloat actualFontSize;
    CGSize size = [songAlbum sizeWithFont:songAlbumLabel.font
                              minFontSize:songAlbumLabel.minimumFontSize
                           actualFontSize:&actualFontSize
                                 forWidth:constrainedSize.width
                            lineBreakMode:songAlbumLabel.lineBreakMode];
    size = [songAlbum sizeWithFont:[songAlbumLabel.font fontWithSize:actualFontSize] constrainedToSize:constrainedSize lineBreakMode:songAlbumLabel.lineBreakMode];
    size.width = MIN(size.width, constrainedSize.width);
    songAlbumLabel.size = size;
    songAlbumLabel.y = songAlbumLabelContainer.width - songAlbumLabel.height;
}

- (UIImage*) imageWithBlur:(UIImage*) image {
    if (!image)
        return nil;
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [[CIImage alloc] initWithImage:image];
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [blurFilter setDefaults];
    [blurFilter setValue:inputImage forKey:@"inputImage"];
    CGFloat blurLevel = 15.0f;          // Set blur level
    [blurFilter setValue:[NSNumber numberWithFloat:blurLevel] forKey:@"inputRadius"];    // set value for blur level
    CIImage *outputImage = [blurFilter valueForKey:@"outputImage"];
    CGRect rect = inputImage.extent;    // Create Rect
    rect.origin.x += blurLevel;         // and set custom params
    rect.origin.y += blurLevel;         //
    rect.size.height -= blurLevel*2.0f; //
    rect.size.width -= blurLevel*2.0f;  //
    CGImageRef cgImage = [context createCGImage:outputImage fromRect:rect];    // Then apply new rect
    UIImage *resultUIImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    return resultUIImage;
}

- (void) reconfigureProgressTimer {
    MPMediaItem *currentItem = [self.musicPlayer nowPlayingItem];
    if (currentItem) {
        self.songDuration = [[currentItem valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
        [self restartSyncTimer];
    }
    else {
        [self cancelSyncTimer];
    }
}

- (void) updateUIGIvenPlaybackState{
    MPMusicPlaybackState playbackState = [self.musicPlayer playbackState];
    if (playbackState == MPMusicPlaybackStatePaused) {
    }
    else if (playbackState == MPMusicPlaybackStatePlaying) {
    }
    else if (playbackState == MPMusicPlaybackStateStopped) {
        [self.musicPlayer stop];
    }
}

- (IBAction)onInformationButtonTUI:(id)sender {
}

#pragma mark - player events
- (void) onMPMusicPlayerControllerPlaybackStateDidChangeNotification:(id) notification{
	[self updateUIGIvenPlaybackState];
}

- (void) onMPMusicPlayerControllerVolumeDidChangeNotification:(id) notification{
    [circularVolumeSlider setValue:[self.musicPlayer volume]];
}

#pragma mark - Controls
- (IBAction)volumeChanged:(id)sender {
    [self.musicPlayer setVolume:[circularVolumeSlider value]];
}

- (IBAction)nextSong:(id)sender {
    [self.musicPlayer skipToNextItem];
}

- (IBAction)previousSong:(id)sender {
    [self.musicPlayer skipToPreviousItem];
}

- (IBAction)playPause:(id)sender {
    if ([self.musicPlayer playbackState] == MPMusicPlaybackStatePlaying) {
        [self.musicPlayer pause];
    }
    else {
        [self.musicPlayer play];
    }
}

- (IBAction)play:(id)sender {
    if ([self.musicPlayer playbackState] != MPMusicPlaybackStatePlaying) {
        [self.musicPlayer play];
    }
}

- (IBAction)pause:(id)sender {
    if ([self.musicPlayer playbackState] == MPMusicPlaybackStatePlaying) {
        [self.musicPlayer pause];
    }
}

- (IBAction)stop:(id)sender {
    [self.musicPlayer stop];
}

- (BOOL) shouldAutorotate {
    return helpView.hidden;
}

- (IBAction)onShowHelpButtonTUI:(id)sender {
    helpView.hidden = NO;
    hideHelpButton.alpha = 0.0;
    helpContentView.alpha = 0.0;
    helpContentView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        contentView.transform = CGAffineTransformMakeScale(0.6, 0.6);
    } completion:^(BOOL finished) {
        
    }];
    
    [UIView animateWithDuration:0.3
                          delay:0.0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
        hideHelpButton.alpha = 1.0;
        helpContentView.alpha = 1.0;
        helpContentView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
    
}

- (IBAction)onHideHelpButtonTUI:(id)sender {
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        contentView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
    }];
    
    [UIView animateWithDuration:0.3
                          delay:0.2
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
        hideHelpButton.alpha = 0.0;
        helpContentView.alpha = 0.0;
        helpContentView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    }
                     completion:^(BOOL finished) {
        helpView.hidden = YES;
    }];
}

#pragma mark - SHARE
- (NSString*) shareText:(NSString*) metadata {
    
    if (metadata && metadata.length > 1)
        return metadata;
    
    NSString* songText = @"";
    
    MPMediaItem *currentItem = [self.musicPlayer nowPlayingItem];
    if (currentItem) {
        NSString* songTitle = [currentItem valueForProperty:MPMediaItemPropertyTitle];
        NSString* songArtist = [currentItem valueForProperty:MPMediaItemPropertyArtist];
        NSString* songAlbum = [currentItem valueForProperty:MPMediaItemPropertyAlbumTitle];
        
        if (songTitle) {
            songText = [songText stringByAppendingString:songTitle];
            if (songArtist)
                songText = [[songText stringByAppendingString:@" by "] stringByAppendingString:songArtist];
        }
        else {
            if (songAlbum) {
                songText = [songText stringByAppendingString:songAlbum];
                if (songArtist)
                    songText = [[songText stringByAppendingString:@" by "] stringByAppendingString:songArtist];
            }
            else {
                songText = songArtist;
            }
        }
    }
    
    if (songText.length > 0) {
        return [NSString stringWithFormat:@"I'm listening to %@ on the GKPlayer made with GestureKit", songText];
    }
    else {
        return @"I'm listening music on the GKPlayer made with GestureKit";
    }
}

- (void) sharetw:(NSString*) metadata {
    [self shareByTwitter:[self shareText:metadata]
                 withURL:@"http://www.gesturekit.com/"
               withImage:nil
      fromViewController:self];
}

- (void) sharefb:(NSString*) metadata {
    [self shareByFacebook:[self shareText:metadata]
                 withURL:@"http://www.gesturekit.com/"
               withImage:nil
      fromViewController:self];
}

- (void)shareByTwitter:(NSString *)tweetText withURL: (NSString *)tweetURL withImage:(UIImage*)image fromViewController:(UIViewController *) parentViewController
{
    Class controllerClass = NSClassFromString(@"TWTweetComposeViewController");
    if (controllerClass)
    {
        if ([controllerClass canSendTweet])
        {
            TWTweetComposeViewController *tweetComposeViewController = [[TWTweetComposeViewController alloc] init];
            [tweetComposeViewController setInitialText:tweetText];
            [tweetComposeViewController addURL:[NSURL URLWithString:tweetURL]];
            [tweetComposeViewController addImage:image];
            [parentViewController presentViewController:tweetComposeViewController animated:YES completion:nil];
            __weak TWTweetComposeViewController* weak_socialController = tweetComposeViewController;
            [tweetComposeViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
                switch (result) {
                    case TWTweetComposeViewControllerResultDone:
                        break;
                    default:
                        // Tweet NO se mando
                        break;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weak_socialController dismissViewControllerAnimated:YES completion:nil];
                });
            }];
            
        }
        else
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Twitter is not setup on this device, please check your device settings.", @"") delegate:nil cancelButtonTitle: NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [alert show];
        }
    }else
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Twitter is not available on this device", @"") delegate:nil cancelButtonTitle: NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
    }
}

- (void) shareByFacebook:(NSString *)faceText withURL: (NSString *)faceURL withImage:(UIImage*)image fromViewController:(UIViewController *) parentViewController
{
    Class controllerClass = NSClassFromString(@"SLComposeViewController");
    if (controllerClass)
    {
        if ([controllerClass isAvailableForServiceType:SLServiceTypeFacebook])
        {
            SLComposeViewController* socialController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            [socialController setInitialText:faceText];
            if (image)
            {
                [socialController addImage:image];
            }
            [socialController addURL:[NSURL URLWithString:faceURL]];
            [parentViewController presentViewController:socialController animated:YES completion:nil];
            __weak SLComposeViewController* weak_socialController = socialController;
            [socialController setCompletionHandler:^(SLComposeViewControllerResult result)
             {
                 switch (result) {
                     case SLComposeViewControllerResultDone:
                         break;
                     default:
                         // facebook NO se mando
                         break;
                 }
                 
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [weak_socialController dismissViewControllerAnimated:YES completion:nil];
                 });
             }];
        }else
        {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Facebook is not setup on this device, please check your device settings..", @"") delegate:nil cancelButtonTitle: NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
            [alert show];
        }
    }else
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Facebook is not available on this device", @"") delegate:nil cancelButtonTitle: NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
        [alert show];
    }
}

@end
