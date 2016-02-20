//
//  PixlHash.h
//  Pods
//
//  Created by Kim Lan Bui on 20/02/16.
//
//

#import <UIKit/UIKit.h>

@interface PixlHash : NSObject

- (id)initWithTileWidth:(NSInteger)width tileHeight:(NSInteger)height;

- (UIImage *)createPixelHashFromString:(NSString *)input;

@end
