//
//  PixlHash.m
//  Pods
//

#import "PixlHash.h"
#import <CommonCrypto/CommonDigest.h>
#import <CoreGraphics/CoreGraphics.h>

#define WIDTH 16
#define HEIGHT 16
#define DEFAULT_TILE_WIDTH 16
#define DEFAULT_TILE_HEIGHT 16
#define FOREGROUND 0
#define BACKGROUND 1
#define COLOR_SIZE 4
#define MINIMUM_COLOR_DISTANCE 1500
#define X_COORDINATE 0
#define Y_COORDINATE 1
#define IS_SET 2

@interface PixlHash ()

@property (nonatomic) NSInteger tileWidth;
@property (nonatomic) NSInteger tileHeight;

@end

@implementation PixlHash

- (id)init {
    self = [super init];
    if (self) {
        self.tileWidth = DEFAULT_TILE_WIDTH;
        self.tileHeight = DEFAULT_TILE_HEIGHT;
    }
    return self;
}

- (id)initWithTileWidth:(NSInteger)width tileHeight:(NSInteger)height {
    self = [super init];
    if (self) {
        self.tileWidth = width;
        self.tileHeight = height;
    }
    return self;
}

- (UIImage *)createPixelHashFromString:(NSString *)input {
    const char *inputChar = [input cStringUsingEncoding:NSASCIIStringEncoding];
    NSData *inputData = [NSData dataWithBytes:inputChar length:strlen(inputChar)];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH] = {0};
    CC_SHA256(inputData.bytes, (int)inputData.length, digest);
    NSData *output = [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];

    CGSize newSize = CGSizeMake(self.tileWidth * WIDTH, self.tileHeight * HEIGHT);
    UIGraphicsBeginImageContext(newSize);

    [self createHash: output];

    UIImage* outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}

#pragma mark Private

- (UIColor *)getColor:(const char *)input fromStartValue:(NSInteger)start {
    NSInteger a = 1.0;
    CGFloat r = ((CGFloat) input[start] / 0xFF);
    if (r < 0) {
        r = 1.0 + r;
    }
    CGFloat g = ((CGFloat) input[start + 1] / 0xFF);
    if (g < 0) {
        g = 1.0 + g;
    }
    CGFloat b = ((CGFloat) input[start + 2] / 0xFF);
    if (b < 0) {
        b = 1.0 + b;
    }
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

- (NSInteger)calculateColorDistanceBetweenFirstColor:(UIColor *)color1 andSecondColor:(UIColor *)color2 {
    CGFloat red1, red2;
    CGFloat green1, green2;
    CGFloat blue1, blue2;
    CGFloat alpha1, alpha2;
    [color1 getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
    [color2 getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];

    NSInteger deltaRed = (NSInteger) (red1 * 0xFF - red2 * 0xFF);
    NSInteger deltaGreen = (NSInteger) (green1 * 0xFF - green2 * 0xFF);
    NSInteger deltaBlue = (NSInteger) (blue1 * 0xFF - blue2 * 0xFF);
    NSInteger deltaAlpha = (NSInteger) (alpha1 * 0xFF - alpha2 * 0xFF);
    return deltaRed * deltaRed + deltaGreen * deltaGreen + deltaBlue * deltaBlue + deltaAlpha * deltaAlpha;
}

- (void)pickColors:(NSData *)input selectFirstColor:(UIColor **)color1 secondColor:(UIColor **)color2 {
    *color1 = [UIColor blackColor];
    *color2 = [UIColor whiteColor];
    for (NSInteger start = 0; start < input.length - 6; start++) {
        *color1 = [self getColor:input.bytes fromStartValue:start];
        *color2 = [self getColor:input.bytes fromStartValue:start + 3];
        if ([self calculateColorDistanceBetweenFirstColor:*color1 andSecondColor:*color2] > MINIMUM_COLOR_DISTANCE) {
            break;
        }
    }
}

- (void)createHash:(NSData *)input {
    UIColor* color1;
    UIColor* color2;
    [self pickColors: input selectFirstColor: &color1 secondColor: &color2];
    [color2 setFill];
    UIRectFill(CGRectMake(0, 0, self.tileWidth * WIDTH, self.tileHeight * HEIGHT));
    [color1 setFill];
    for (NSInteger position = 0; position < (input.length - 1) * 4; position++) {
        NSInteger x;
        NSInteger y;
        NSInteger set;
        [self getPixelData: input atPosition: position outputX: &x outputY: &y outputSet: &set];
        if (set) {
            [self drawRectAtXCoord: x AndYCoord: y];
        }
    }
}

- (void)getPixelData:(NSData *)input atPosition:(NSInteger)position outputX:(NSInteger *)x outputY:(NSInteger *)y outputSet:(NSInteger *)set {
    NSInteger offset = position / (input.length - 1) * 2;
    NSInteger start = position % (input.length - 1);
    const uint8_t* bytes = [input bytes];
    NSInteger data = (((NSInteger) bytes[start]) & 0xFF) << 8 | (((NSInteger) bytes[start + 1]) & 0xFF);
    NSInteger coordinateData = (data >> (16 - 7 - offset)) & 0x7F;
    *set = (data >> (16 - 8 - offset)) % 2;
    *x = coordinateData % 8;
    *y = coordinateData / 8;
}

- (void)drawRectAtXCoord:(NSInteger)x AndYCoord:(NSInteger)y {
    UIRectFill(CGRectMake(x * self.tileWidth, y * self.tileHeight, self.tileWidth, self.tileHeight));
    UIRectFill(CGRectMake((WIDTH - x - 1) * self.tileWidth, y * self.tileHeight, self.tileWidth, self.tileHeight));
}

@end