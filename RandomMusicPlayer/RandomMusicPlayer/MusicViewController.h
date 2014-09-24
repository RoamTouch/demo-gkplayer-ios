//
//  MusicViewController.h
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#import "UICircularSlider.h"
#import "THCircularProgressView.h"

@interface MusicViewController : UIViewController <MPMediaPickerControllerDelegate> {
    __weak IBOutlet UIImageView *artworkImageView;
    __weak IBOutlet UILabel *songArtistAndSongTitleLabel;
    
    __weak IBOutlet UIView *songAlbumLabelContainer;
    __weak IBOutlet UILabel *songAlbumLabel;
    
    __weak IBOutlet UIView *playerView;
    __weak IBOutlet UIView *discView;
    __weak IBOutlet UIImageView *discArtwork;
    
    __weak IBOutlet UIView *artworkColorBackground;
    __weak IBOutlet UILabel *currentSontTimeLabel;
    
    __weak IBOutlet UIView *helpView;
    __weak IBOutlet UIButton *hideHelpButton;
    __weak IBOutlet UIView *helpContentView;
    __weak IBOutlet UIView *contentView;
    
    __weak IBOutlet UICircularSlider *circularVolumeSlider;
    __weak IBOutlet UIView *mpVolumeViewParentView;
    __weak IBOutlet THCircularProgressView *currentSongCircularProgressView;
    __weak IBOutlet THCircularProgressView *innnerRingView;
    
}

- (IBAction)volumeChanged:(id)sender;

- (IBAction)previousSong:(id)sender;
- (IBAction)nextSong:(id)sender;
- (IBAction)playPause:(id)sender;

- (IBAction)play:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)stop:(id)sender;

- (void) sharetw:(NSString*) metadata;
- (void) sharefb:(NSString*) metadata;

- (IBAction)onShowHelpButtonTUI:(id)sender;
- (IBAction)onHideHelpButtonTUI:(id)sender;

@end
