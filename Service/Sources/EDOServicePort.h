//
// Copyright 2018 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  The port to identify a @c EDOHostService.
 */
@interface EDOServicePort : NSObject <NSSecureCoding>

/** The port that the service listens on. */
@property(nonatomic, readonly) UInt16 port;

/** Check if the two @c EDOServicePort has the same identity. */
- (BOOL)match:(EDOServicePort *)otherPort;

/** Create an instance with a given port number. */
+ (instancetype)servicePortWithPort:(UInt16)port;
@end

NS_ASSUME_NONNULL_END
