#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "BITTestsDependencyInjection.h"
#import "BITTelemetryManagerPrivate.h"
#import "BITHockeyBaseManagerPrivate.h"
#import "BITSession.h"
#import "BITChannel.h"
#import "BITTelemetryContext.h"
#import "BITSessionStateData.h"

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#define MOCKITO_SHORTHAND
#import <OCMockitoIOS/OCMockitoIOS.h>

@interface BITTelemetryManagerTests : BITTestsDependencyInjection

@property (strong) BITTelemetryManager *sut;

@end

@implementation BITTelemetryManagerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    [super tearDown];
}

- (void)testTelemetryManagerGetsInstantiated {
  self.sut = [BITTelemetryManager new];
  XCTAssertNotNil(self.sut, @"Should not be nil.");
}

- (void)testDependenciesAreCreatedCorrectly {
  self.sut = [BITTelemetryManager new];
  
  BITPersistence *persistence = self.sut.persistence;
  XCTAssertNotNil(persistence);
  
  BITTelemetryContext *context = self.sut.telemetryContext;
  XCTAssertNotNil(persistence);
  XCTAssertEqualObjects(persistence, context.persistence);
  
  BITChannel *channel = self.sut.channel;
  XCTAssertNotNil(persistence);
  XCTAssertEqualObjects(persistence, channel.persistence);
  XCTAssertEqualObjects(context, channel.telemetryContext);
}

- (void)testNewSessionIsCreatedCorrectly {
  NSUserDefaults *defaults = [NSUserDefaults new];
  self.sut = [[BITTelemetryManager alloc]initWithChannel:nil telemetryContext:nil persistence:nil userDefaults:defaults];
  NSString *testSessionId1 = @"12345";
  NSString *testSessionId2 = @"67890";
  
  // First session
  BITSession *actualSession1 = [self.sut createNewSessionWithId:testSessionId1];
  XCTAssertEqualObjects(actualSession1.sessionId, testSessionId1);
  XCTAssertEqualObjects(actualSession1.isNew, @"true");
  XCTAssertEqualObjects(actualSession1.isFirst, @"true");
  
  // Next sessions
  BITSession *actualSession2 = [self.sut createNewSessionWithId:testSessionId2];
  XCTAssertEqualObjects(actualSession2.sessionId, testSessionId2);
  XCTAssertEqualObjects(actualSession2.isNew, @"true");
  XCTAssertEqualObjects(actualSession2.isFirst, @"false");
}

- (void)testRegisterObserversOnStart {
  self.mockNotificationCenter = mock(NSNotificationCenter.class);
  self.sut = [BITTelemetryManager new];
  [self.sut startManager];
  
  [verify((id)self.mockNotificationCenter) addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:(id)anything()];
  [verify((id)self.mockNotificationCenter) addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:(id)anything()];
}

- (void)testTrackSessionEnqueuesObject {
  BITChannel *channel = [BITChannel new];
  id mockChannel = OCMPartialMock(channel);
  self.sut = [[BITTelemetryManager alloc] initWithChannel:mockChannel telemetryContext:nil persistence:nil userDefaults:nil];
  
  OCMExpect([mockChannel enqueueTelemetryItem:[OCMArg checkWithBlock:^BOOL(NSObject *value)
                                             {
                                               return [value isKindOfClass:[BITSessionStateData class]];
                                             }]]);
  [self.sut trackSessionWithState:BITSessionState_start];
  OCMVerifyAll(mockChannel);
}

- (void)testNewSessionUpdatesSessionContext {
  BITTelemetryContext *context = [BITTelemetryContext new];
  id mockContext = OCMPartialMock(context);
  NSUserDefaults *defaults = [NSUserDefaults new];
  self.sut = [[BITTelemetryManager alloc]initWithChannel:nil telemetryContext:nil persistence:nil userDefaults:defaults];
  NSString *testSessionId = @"sessionId";
  
  OCMExpect([mockContext setSessionId:testSessionId]);
  OCMExpect([mockContext setIsNewSession:@"true"]);
  OCMExpect([mockContext setIsFirstSession:@"true"]);
  
  [self.sut startNewSessionWithId:testSessionId];
  OCMVerifyAll(mockContext);
}

@end
