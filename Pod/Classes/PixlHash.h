//
//  PixlHash.h
//  Pods
//

#import <UIKit/UIKit.h>

@interface PixlHash : NSObject

- (id)initWithTileWidth:(NSInteger)width tileHeight:(NSInteger)height;

- (UIImage *)createPixelHashFromString:(NSString *)input;

@end
