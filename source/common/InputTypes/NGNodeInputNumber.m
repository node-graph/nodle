#import "NGNodeInputNumber.h"

@implementation NGNodeInputNumber
@dynamic value;

- (instancetype)initWithKey:(NSString *)key node:(nullable id<NGNodeInputDelegate, NGNode>)node {
    self = [self initWithKey:key
                  validation:^BOOL(id  _Nonnull value) {return [value isKindOfClass:[NSNumber class]];}
                        node:node];
    return self;
}

@end
