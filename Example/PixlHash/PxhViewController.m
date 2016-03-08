//
//  PxhViewController.m
//  PixlHash
//

#import "PxhViewController.h"
#import <PixlHash/PixlHash.h>

@interface PxhViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *pxhTextField;
@property (nonatomic, weak) IBOutlet UIImageView *pxhImageView;

@end

@implementation PxhViewController

- (void)startTextToImageConversion {
    UIImage *convertedImage = [self generateImageFromText:self.pxhTextField.text];
    [self.pxhImageView setImage:convertedImage];
}

- (void)showErrorMessage {
    
}

- (UIImage *)generateImageFromText:(NSString *)text {
    PixlHash *pixlHash = [[PixlHash alloc] init];
    return [pixlHash createPixelHashFromString:text];
}

#pragma mark IBActions

- (IBAction)didTapGenerateButton:(id)sender {
    if ([self.pxhTextField.text length] == 0) {
        [self showErrorMessage];
        return;
    }
    
    [self startTextToImageConversion];
}

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ([textField.text length] == 0) {
        [self showErrorMessage];
        return YES;
    }
    
    [self startTextToImageConversion];
    return YES;
}

@end
