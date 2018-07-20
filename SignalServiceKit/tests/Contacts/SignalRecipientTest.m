//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "SignalRecipient.h"
#import "MockSSKEnvironment.h"
#import "OWSPrimaryStorage.h"
#import "SSKBaseTest.h"
#import "TSAccountManager.h"
#import "TestAppContext.h"
#import <SignalServiceKit/SignalServiceKit-Swift.h>

@interface TSAccountManager (Testing)

- (void)storeLocalNumber:(NSString *)localNumber;

@end

@interface SignalRecipientTest : SSKBaseTest

@property (nonatomic) NSString *localNumber;

@end

@implementation SignalRecipientTest

- (void)setUp
{
    [super setUp];

    [MockSSKEnvironment activate];

    self.localNumber = @"+13231231234";
    [[TSAccountManager sharedInstance] storeLocalNumber:self.localNumber];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testSelfRecipientWithExistingRecord
{
    // Sanity Check
    XCTAssertNotNil(self.localNumber);

    [OWSPrimaryStorage.sharedManager.dbReadWriteConnection
        readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [SignalRecipient markRecipientAsRegisteredAndGet:self.localNumber transaction:transaction];

            XCTAssertTrue([SignalRecipient isRegisteredRecipient:self.localNumber transaction:transaction]);

            SignalRecipient *me = [SignalRecipient selfRecipientWithTransaction:transaction];
            XCTAssertNotNil(me);
            XCTAssertEqualObjects(self.localNumber, me.uniqueId);
        }];
}

- (void)testSelfRecipientWithoutExistingRecord
{
    XCTAssertNotNil(self.localNumber);

    [OWSPrimaryStorage.sharedManager.dbReadWriteConnection
        readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [[SignalRecipient fetchObjectWithUniqueID:self.localNumber] removeWithTransaction:transaction];

            XCTAssertFalse([SignalRecipient isRegisteredRecipient:self.localNumber transaction:transaction]);

            SignalRecipient *me = [SignalRecipient selfRecipientWithTransaction:transaction];
            XCTAssertNil(me);
            XCTAssertEqualObjects(self.localNumber, me.uniqueId);
        }];
}

@end
