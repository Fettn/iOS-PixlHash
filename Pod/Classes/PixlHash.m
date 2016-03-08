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
    uint8_t *hash = calloc(self.tileWidth * WIDTH * self.tileHeight * HEIGHT * 4, sizeof(uint8_t));
    [self createHash: output withHash: hash];
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, hash, self.tileWidth * WIDTH * self.tileHeight * HEIGHT * 4, NULL);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaFirst;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(self.tileWidth * WIDTH, self.tileHeight * HEIGHT, 8, 32, 4 * self.tileWidth * WIDTH, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    UIImage* image = [UIImage imageWithCGImage:imageRef];
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    free(hash);
    return image;
}

#pragma mark Private

- (NSInteger)getColor:(const char *)input fromStartValue:(NSInteger)start {
    NSInteger ret = 0xFF;
    for (NSInteger offset = 0; offset < 3; offset++) {
        ret *= 256;
        ret += input[start + offset];
    }
    return ret;
}

- (NSInteger)calculateColorDistanceBetweenFirstColor:(NSInteger)color1 andSecondColor:(NSInteger)color2 {
    NSInteger sum = 0;
    for (NSInteger i = 0; i < COLOR_SIZE; i++) {
        NSInteger diff = color1 % 256 - color2 % 256;
        sum += diff * diff;
        color1 /= 256;
        color2 /= 256;
    }
    return sum;
}

- (void)pickColors:(NSData *)input selectFirstColor:(NSInteger *)color1 secondColor:(NSInteger *)color2 {
    *color1 = 0xFFFFFF;
    *color2 = 0;
    for (NSInteger start = 0; start < input.length - 6; start++) {
        *color1 = [self getColor:input.bytes fromStartValue:start];
        *color2 = [self getColor:input.bytes fromStartValue:start + 3];
        if ([self calculateColorDistanceBetweenFirstColor:*color1 andSecondColor:*color2] > MINIMUM_COLOR_DISTANCE) {
            break;
        }
    }
}

- (void) createHash:(NSData *)input withHash:(uint8_t *)hash {
    NSInteger color1;
    NSInteger color2;
    [self pickColors: input selectFirstColor: &color1 secondColor: &color2];
    NSInteger len = WIDTH * self.tileWidth * HEIGHT * self.tileHeight;
    for (NSInteger position = 0; position < len; position++) {
        [self setColor:hash position:position * 4 color:color2];
    }
    for (NSInteger position = 0; position < (input.length - 1) * 4; position++) {
        NSInteger x;
        NSInteger y;
        NSInteger set;
        [self getPixelData: input atPosition: position outputX: &x outputY: &y outputSet: &set];
        if (set) {
            [self drawRect: hash xCoord: x yCoord: y withColor: color1];
        }
    }
}

- (void) getPixelData:(NSData *)input atPosition:(NSInteger)position outputX:(NSInteger *)x outputY:(NSInteger *)y outputSet:(NSInteger *)set {
    NSInteger offset = position / (input.length - 1) * 2;
    NSInteger start = position % (input.length - 1);
    const uint8_t* bytes = [input bytes];
    NSInteger data = (((NSInteger) bytes[start]) & 0xFF) << 8 | (((NSInteger) bytes[start + 1]) & 0xFF);
    NSInteger coordinateData = (data >> (16 - 7 - offset)) & 0x7F;
    *set = (data >> (16 - 8 - offset)) % 2;
    *x = coordinateData % 8;
    *y = coordinateData / 8;
}

- (void) drawRect:(uint8_t *)hash xCoord:(NSInteger)x yCoord:(NSInteger)y withColor:(NSInteger)color {
    for (NSInteger deltaY = 0; deltaY < self.tileHeight; deltaY++) {
        for (NSInteger deltaX = 0; deltaX < self.tileWidth; deltaX++) {
            NSInteger pos1 = ((y * self.tileHeight + deltaY) * (WIDTH * self.tileWidth) + (x * self.tileWidth) + deltaX);
            NSInteger pos2 = ((y * self.tileHeight + deltaY) * (WIDTH * self.tileWidth) + ((WIDTH - x - 1) * self.tileWidth) + deltaX);
            [self setColor: hash position:pos1 * 4 color: color];
            [self setColor: hash position:pos2 * 4 color: color];
        }
    }
}

- (void) setColor:(uint8_t *)field position:(NSInteger)position color:(NSInteger)color {
    for (NSInteger b = 3; b >= 0; b--) {
        field[position + b] = color % 256;
        field[position + b] = color % 256;
        color /= 256;
    }
}

@end