//
//  NSURLSessionTask+IMQA.h
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSessionTask (IMQA)

- (BOOL)injectHeaderWithKey:(NSString *)key value:(NSString *)value;

@end

NS_ASSUME_NONNULL_END
