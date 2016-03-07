//
//  PixlHash.m
//  Pods
//
//  Created by Kim Lan Bui on 20/02/16.
//
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
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, output.bytes, self.tileWidth * self.tileHeight * 4, NULL);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(self.tileWidth, self.tileHeight, 8, 32, 4 * self.tileWidth, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    return [UIImage imageWithCGImage:imageRef];
}

#pragma mark Private

- (int)getColor:(const char *)input fromStartValue:(int)start {
    int ret = 0xFF;
    for (int offset = 0; offset < 3; offset++) {
        ret *= 256;
        ret += input[start + offset];
    }
    return ret;
}

- (int)calculateColorDistanceBetweenFirstColor:(int)color1 andSecondColor:(int)color2 {
    int sum = 0;
    for (int i = 0; i < COLOR_SIZE; i++) {
        int diff = color1 % 256 - color2 % 256;
        sum += diff * diff;
        color1 /= 256;
        color2 /= 256;
    }
    return sum;
}

- (void)pickColors:(NSData *)input selectFirstColor:(int **)color1 secondColor:(int **)color2 {
    // int color1 = 0xFFFFFF;
    // int color2 = 0;
    for (int start = 0; start < input.length - 6; start++) {
        *color1 = [self getColor:input.bytes fromStartValue:start];
        *color2 = [self getColor:input.bytes fromStartValue:start + 3];
        if ([self calculateColorDistanceBetweenFirstColor:color1 andSecondColor:color2] > MINIMUM_COLOR_DISTANCE) {
            break;
        }
    }
}

@end

/*
public class PixlHash {
 
    public Bitmap getPixlHash(String input) {
        byte[] hash = messageDigest.digest(input.getBytes());
        return getPixlHash(hash);
    }
    
    protected Bitmap getPixlHash(byte[] input) {
        int[] image = createHash(input);
        return Bitmap.createBitmap(image, WIDTH * tileWidth, HEIGHT * tileHeight, Bitmap.Config.ARGB_8888);
    }
    
    private int[] createHash(byte[] input) {
        int[] colors = pickColors(input);
        int[] hash = new int[WIDTH * tileWidth * HEIGHT * tileHeight];
        for (int position = 0; position < hash.length; position++) {
            hash[position] = colors[BACKGROUND];
        }
        
        for (int position = 0; position < (input.length - 1) * 4; position++) {
            int[] pixel = getPixelData(input, position);
            boolean set = pixel[IS_SET] != 0;
            if (set) {
                int x = pixel[X_COORDINATE];
                int y = pixel[Y_COORDINATE];
                drawRect(hash, x, y, colors[FOREGROUND]);
            }
        }
        
        return hash;
    }
    
    private void drawRect(int[] hash, int x, int y, int color) {
        for (int deltaY = 0; deltaY < tileHeight; deltaY++) {
            for (int deltaX = 0; deltaX < tileWidth; deltaX++) {
                int pos1 = ((y * tileHeight + deltaY) * (WIDTH * tileWidth) + (x * tileWidth) + deltaX);
                int pos2 = ((y * tileHeight + deltaY) * (WIDTH * tileWidth) + ((WIDTH - x - 1) * tileWidth) + deltaX);
                hash[pos1] = color;
                hash[pos2] = color;
            }
        }
    }
    
    protected static int[] getPixelData(byte[] input, int position) {
        int offset = position / (input.length - 1);
        int start = position % (input.length - 1);
        long data = (((long) input[start]) & 0xFF) << 8 | (((long) input[start + 1]) & 0xFF);
        int coordinateData = (int) ((data >> (16 - 7 - offset)) & 0x7F);
        int setData = (int) ((data >> (16 - 8 - offset)) % 2);
        return new int[]{coordinateData % 8, coordinateData / 8, setData};
    }
}

*/