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

#import <XCTest/XCTest.h>

#import "Channel/Sources/EDOChannelPool.h"
#import "Channel/Sources/EDOHostPort.h"
#import "Channel/Sources/EDOSocket.h"
#import "Channel/Sources/EDOSocketChannel.h"
#import "Channel/Sources/EDOSocketPort.h"

@interface EDOChannelPoolTest : XCTestCase

@end

@implementation EDOChannelPoolTest

- (void)testSimpleFetchAndReleaseAfterCreate {
  EDOSocket *host = [EDOSocket listenWithTCPPort:0 queue:nil connectedBlock:nil];
  EDOChannelPool *channelPool = EDOChannelPool.sharedChannelPool;
  __block NSMutableArray<EDOSocketChannel *> *channels =
      [[NSMutableArray alloc] initWithCapacity:10];
  for (int i = 0; i < 10; i++) {
    id<EDOChannel> socketChannel = [channelPool
        fetchConnectedChannelWithPort:[EDOHostPort hostPortWithLocalPort:host.socketPort.port]
                                error:nil];
    [channels addObject:socketChannel];
    [channelPool addChannel:socketChannel];
  }
  XCTAssertEqual(
      [channelPool countChannelsWithPort:[EDOHostPort hostPortWithLocalPort:host.socketPort.port]],
      1u);
  for (int i = 0; i < 9; i++) {
    XCTAssertEqual(channels[i], channels[i + 1]);
  }
  [channelPool removeChannelsWithPort:[EDOHostPort hostPortWithLocalPort:host.socketPort.port]];
}

- (void)testAsyncCreateChannels {
  EDOSocket *host1 = [EDOSocket listenWithTCPPort:0 queue:nil connectedBlock:nil];
  EDOSocket *host2 = [EDOSocket listenWithTCPPort:0 queue:nil connectedBlock:nil];
  NSMutableSet<EDOSocketChannel *> *set1 = [[NSMutableSet alloc] init];
  NSMutableSet<EDOSocketChannel *> *set2 = [[NSMutableSet alloc] init];
  dispatch_queue_t queue = dispatch_queue_create("channel set sync queue", DISPATCH_QUEUE_SERIAL);
  EDOChannelPool *channelPool = EDOChannelPool.sharedChannelPool;

  for (int i = 0; i < 10; i++) {
    UInt16 port = i % 2 == 0 ? host1.socketPort.port : host2.socketPort.port;
    NSMutableSet *set = i % 2 == 0 ? set1 : set2;
    id<EDOChannel> socketChannel =
        [channelPool fetchConnectedChannelWithPort:[EDOHostPort hostPortWithLocalPort:port]
                                             error:nil];

    [channelPool addChannel:socketChannel];
    dispatch_sync(queue, ^{
      [set addObject:socketChannel];
    });
  };

  NSUInteger host1ChannelCount =
      [channelPool countChannelsWithPort:[EDOHostPort hostPortWithLocalPort:host1.socketPort.port]];
  NSUInteger host2ChannelCount =
      [channelPool countChannelsWithPort:[EDOHostPort hostPortWithLocalPort:host2.socketPort.port]];
  XCTAssertEqual(host1ChannelCount + host2ChannelCount, set1.count + set2.count);
  [channelPool removeChannelsWithPort:[EDOHostPort hostPortWithLocalPort:host1.socketPort.port]];
  [channelPool removeChannelsWithPort:[EDOHostPort hostPortWithLocalPort:host2.socketPort.port]];
}

- (void)testClearChannelWithPort {
  EDOSocket *host = [EDOSocket listenWithTCPPort:0 queue:nil connectedBlock:nil];
  EDOChannelPool *channelPool = EDOChannelPool.sharedChannelPool;
  id<EDOChannel> socketChannel = [channelPool
      fetchConnectedChannelWithPort:[EDOHostPort hostPortWithLocalPort:host.socketPort.port]
                              error:nil];
  [channelPool addChannel:socketChannel];

  [channelPool removeChannelsWithPort:[EDOHostPort hostPortWithLocalPort:host.socketPort.port]];
  XCTAssertEqual(
      [channelPool countChannelsWithPort:[EDOHostPort hostPortWithLocalPort:host.socketPort.port]],
      0u);
}

- (void)testReleaseInvalidChannel {
  EDOSocket *host = [EDOSocket listenWithTCPPort:0 queue:nil connectedBlock:nil];
  EDOChannelPool *channelPool = EDOChannelPool.sharedChannelPool;
  id<EDOChannel> channel = [channelPool
      fetchConnectedChannelWithPort:[EDOHostPort hostPortWithLocalPort:host.socketPort.port]
                              error:nil];
  [channel invalidate];
  [channelPool addChannel:channel];
  XCTAssertEqual(
      [channelPool countChannelsWithPort:[EDOHostPort hostPortWithLocalPort:host.socketPort.port]],
      0u);
  [channelPool removeChannelsWithPort:[EDOHostPort hostPortWithLocalPort:host.socketPort.port]];
}

- (void)testClearInvalidPort {
  // channel pool should be empty now
  EDOChannelPool *channelPool = EDOChannelPool.sharedChannelPool;
  // trigger two times to make sure clear a non-existing port.
  XCTAssertNoThrow([channelPool removeChannelsWithPort:[EDOHostPort hostPortWithLocalPort:12345]]);
  XCTAssertNoThrow([channelPool removeChannelsWithPort:[EDOHostPort hostPortWithLocalPort:12345]]);
}

/**
 *  Tests register a dummy service name in the app process, and verifies that the host channel can
 *  receive test message from the app client channel.
 */
- (void)testConnectChannelWithServiceName {
  UInt16 serviceConnectionPort = EDOChannelPool.sharedChannelPool.serviceConnectionPort;
  NSString *dummyServiceName = @"dummyServiceName";
  __block EDOSocketChannel *hostChannel;

  // Connect to name registration port and send dummy service name.
  XCTestExpectation *expectation = [self expectationWithDescription:@"HostChannelSetupExpectation"];
  [EDOSocket connectWithTCPPort:serviceConnectionPort
                          queue:dispatch_get_main_queue()
                 connectedBlock:^(EDOSocket *socket, UInt16 listenPort, NSError *error) {
                   hostChannel = [EDOSocketChannel channelWithSocket:socket];
                   NSData *data = [dummyServiceName dataUsingEncoding:NSUTF8StringEncoding];
                   [hostChannel sendData:data
                       withCompletionHandler:^(id<EDOChannel> channel, NSError *error) {
                         XCTAssertNil(error);
                         [expectation fulfill];
                       }];
                 }];
  [self waitForExpectationsWithTimeout:2 handler:nil];

  // Send dummy message with the connected client channel in the channel pool.
  NSString *dummyMessage = @"EDODummyMessage";
  id<EDOChannel> socketChannel = [EDOChannelPool.sharedChannelPool
      fetchConnectedChannelWithPort:[EDOHostPort hostPortWithName:dummyServiceName]
                              error:nil];
  NSData *data = [dummyMessage dataUsingEncoding:NSUTF8StringEncoding];
  [socketChannel sendData:data
      withCompletionHandler:^(id<EDOChannel> channel, NSError *error) {
        [EDOChannelPool.sharedChannelPool addChannel:channel];
      }];

  __block NSString *testMessage;
  expectation = [self expectationWithDescription:@"ReceiveTestMessage"];
  [hostChannel receiveDataWithHandler:^(id<EDOChannel> channel, NSData *data, NSError *error) {
    XCTAssertNil(error);
    testMessage = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:2 handler:nil];
  // Verify the test message received is equal to the original dummy test message.
  XCTAssertEqualObjects(testMessage, dummyMessage);
}

@end
