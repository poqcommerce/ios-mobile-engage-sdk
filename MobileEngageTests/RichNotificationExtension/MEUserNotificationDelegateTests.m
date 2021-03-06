#import "Kiwi.h"
#import "MobileEngage.h"
#import "MobileEngageInternal.h"
#import <UserNotifications/UNNotification.h>
#import <UserNotifications/UNNotificationResponse.h>
#import <UserNotifications/UNNotificationRequest.h>
#import <UserNotifications/UNNotificationContent.h>
#import "MEUserNotificationDelegate.h"
#import "MEExperimental.h"
#import "MEExperimental+Test.h"
#import "MEIAMProtocol.h"
#import "KWReceiveMatcher.h"
#import "MEInAppMessage.h"

SPEC_BEGIN(MEUserNotificationDelegateTests)
        if (@available(iOS 10.0, *)) {
            id (^notificationResponseWithUserInfoWithActionId)(NSDictionary *userInfo, NSString *actionId) = ^id(NSDictionary *userInfo, NSString *actionId) {
                UNNotificationResponse *response = [UNNotificationResponse mock];
                UNNotification *notification = [UNNotification mock];
                UNNotificationRequest *request = [UNNotificationRequest mock];
                UNNotificationContent *content = [UNNotificationContent mock];
                [response stub:@selector(notification) andReturn:notification];
                [response stub:@selector(actionIdentifier) andReturn:actionId];
                [notification stub:@selector(request) andReturn:request];
                [request stub:@selector(content) andReturn:content];
                [content stub:@selector(userInfo) andReturn:userInfo];
                return response;
            };

            id (^notificationResponseWithUserInfo)(NSDictionary *userInfo) = ^id(NSDictionary *userInfo) {
                return notificationResponseWithUserInfoWithActionId(userInfo, @"uniqueId");
            };

            describe(@"init", ^{
                it(@"should throw an exception when there is no application", ^{
                    @try {
                        [[MEUserNotificationDelegate alloc] initWithApplication:nil
                                                           mobileEngageInternal:[MobileEngageInternal mock]
                                                                          inApp:[MEInApp mock]];
                        fail(@"Expected Exception when application is nil!");
                    } @catch (NSException *exception) {
                        [[exception.reason should] equal:@"Invalid parameter not satisfying: application"];
                        [[theValue(exception) shouldNot] beNil];
                    }
                });

                it(@"should throw an exception when there is no mobileEngageInternal", ^{
                    @try {
                        [[MEUserNotificationDelegate alloc] initWithApplication:[UIApplication mock]
                                                           mobileEngageInternal:nil
                                                                          inApp:[MEInApp mock]];
                        fail(@"Expected Exception when mobileEngage is nil!");
                    } @catch (NSException *exception) {
                        [[exception.reason should] equal:@"Invalid parameter not satisfying: mobileEngage"];
                        [[theValue(exception) shouldNot] beNil];
                    }
                });

                it(@"should throw an exception when there is no inApp", ^{
                    @try {
                        [[MEUserNotificationDelegate alloc] initWithApplication:[UIApplication mock]
                                                           mobileEngageInternal:[MobileEngageInternal mock]
                                                                          inApp:nil];
                        fail(@"Expected Exception when inApp is nil!");
                    } @catch (NSException *exception) {
                        [[exception.reason should] equal:@"Invalid parameter not satisfying: inApp"];
                        [[theValue(exception) shouldNot] beNil];
                    }
                });
            });

            describe(@"userNotificationCenter:willPresentNotification:withCompletionHandler:", ^{

                it(@"should call the injected delegate's userNotificationCenter:willPresentNotification:withCompletionHandler: method", ^{
                    id userNotificationCenterDelegate = [KWMock mockForProtocol:@protocol(UNUserNotificationCenterDelegate)];
                    UNUserNotificationCenter *mockCenter = [UNUserNotificationCenter mock];
                    UNNotification *mockNotification = [UNNotification mock];
                    void (^ const completionHandler)(UNNotificationPresentationOptions)=^(UNNotificationPresentationOptions options) {
                    };

                    [[userNotificationCenterDelegate should] receive:@selector(userNotificationCenter:willPresentNotification:withCompletionHandler:) withArguments:mockCenter, mockNotification, completionHandler];

                    MEUserNotificationDelegate *userNotification = [MEUserNotificationDelegate new];
                    userNotification.delegate = userNotificationCenterDelegate;

                    [userNotification userNotificationCenter:mockCenter
                                     willPresentNotification:mockNotification
                                       withCompletionHandler:completionHandler];
                });

                it(@"should call completion handler with UNNotificationPresentationOptionAlert", ^{
                    MEUserNotificationDelegate *userNotification = [MEUserNotificationDelegate new];
                    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                    __block UNNotificationPresentationOptions _option;
                    [userNotification userNotificationCenter:nil
                                     willPresentNotification:nil
                                       withCompletionHandler:^(UNNotificationPresentationOptions options) {
                                           _option = options;
                                           [exp fulfill];
                                       }];

                    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:5];
                    [[theValue(result) should] equal:theValue(XCTWaiterResultCompleted)];
                    [[theValue(_option) should] equal:theValue(UNNotificationPresentationOptionAlert)];
                });

            });

            describe(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:", ^{

                it(@"should call the injected delegate's userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: method", ^{
                    id userNotificationCenterDelegate = [KWMock mockForProtocol:@protocol(UNUserNotificationCenterDelegate)];
                    UNUserNotificationCenter *center = [UNUserNotificationCenter nullMock];
                    UNNotificationResponse *notificationResponse = [UNNotificationResponse nullMock];
                    void (^ const completionHandler)()=^{
                    };

                    [[userNotificationCenterDelegate should] receive:@selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:) withArguments:center, notificationResponse, completionHandler];

                    MEUserNotificationDelegate *userNotification = [[MEUserNotificationDelegate alloc] initWithApplication:[UIApplication mock] mobileEngageInternal:[MobileEngageInternal nullMock] inApp:[MEInApp nullMock]];
                    userNotification.delegate = userNotificationCenterDelegate;

                    [userNotification userNotificationCenter:center
                              didReceiveNotificationResponse:notificationResponse
                                       withCompletionHandler:completionHandler];
                });

                it(@"should call completion handler", ^{
                    MEUserNotificationDelegate *userNotification = [MEUserNotificationDelegate new];
                    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                    [userNotification userNotificationCenter:nil didReceiveNotificationResponse:nil withCompletionHandler:^{
                        [exp fulfill];
                    }];

                    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[exp] timeout:5];
                    [[theValue(result) should] equal:theValue(XCTWaiterResultCompleted)];
                });

                it(@"should call MobileEngage.notification.eventHandler with the defined eventName and payload if the action is type of MEAppEvent", ^{
                    id eventHandlerMock = [KWMock mockForProtocol:@protocol(MEEventHandler)];
                    NSString *eventName = @"testEventName";
                    NSDictionary *payload = @{@"key1": @"value1", @"key2": @"value2", @"key3": @"value3"};
                    [[eventHandlerMock should] receive:@selector(handleEvent:payload:) withArguments:eventName, payload];

                    MEUserNotificationDelegate *userNotification = [MEUserNotificationDelegate new];
                    userNotification.eventHandler = eventHandlerMock;

                    NSDictionary *userInfo = @{@"ems": @{
                        @"actions": @[
                            @{
                                @"id": @"uniqueId",
                                @"title": @"actionTitle",
                                @"type": @"MEAppEvent",
                                @"name": eventName,
                                @"payload": payload
                            }
                        ]}};

                    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                    [userNotification userNotificationCenter:nil
                              didReceiveNotificationResponse:notificationResponseWithUserInfo(userInfo)
                                       withCompletionHandler:^{
                                           [exp fulfill];
                                       }];
                    [XCTWaiter waitForExpectations:@[exp] timeout:5];
                });

                it(@"should not call MobileEngage.notification.eventHandler with the defined eventName and payload if the action is not MEAppEvent type", ^{
                    id eventHandlerMock = [KWMock mockForProtocol:@protocol(MEEventHandler)];
                    [[eventHandlerMock shouldNot] receive:@selector(handleEvent:payload:)];

                    MEUserNotificationDelegate *userNotification = [MEUserNotificationDelegate new];
                    userNotification.eventHandler = eventHandlerMock;

                    NSDictionary *userInfo = @{@"ems": @{
                        @"actions": @[
                            @{
                                @"id": @"uniqueId",
                                @"title": @"actionTitle",
                                @"type": @"someStuff",
                                @"name": @"testEventName",
                                @"payload": @{@"key1": @"value1", @"key2": @"value2", @"key3": @"value3"}
                            }
                        ]}};

                    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                    [userNotification userNotificationCenter:nil
                              didReceiveNotificationResponse:notificationResponseWithUserInfo(userInfo)
                                       withCompletionHandler:^{
                                           [exp fulfill];
                                       }];
                    [XCTWaiter waitForExpectations:@[exp] timeout:5];
                });

                it(@"should call trackCustomEvent on MobileEngage with the defined eventName and payload if the action is type of MECustomEvent", ^{
                    NSString *eventName = @"testEventName";
                    NSDictionary *payload = @{@"key1": @"value1", @"key2": @"value2", @"key3": @"value3"};
                    MobileEngageInternal *mobileEngage = [MobileEngageInternal nullMock];

                    MEUserNotificationDelegate *userNotification = [[MEUserNotificationDelegate alloc] initWithApplication:[UIApplication mock] mobileEngageInternal:mobileEngage inApp:[MEInApp nullMock]];
                    NSDictionary *userInfo = @{@"ems": @{
                        @"actions": @[
                            @{
                                @"id": @"uniqueId",
                                @"title": @"actionTitle",
                                @"type": @"MECustomEvent",
                                @"name": eventName,
                                @"payload": payload
                            }
                        ]}};
                    [[mobileEngage should] receive:@selector(trackCustomEvent:eventAttributes:) withArguments:eventName, payload];

                    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                    [userNotification userNotificationCenter:nil
                              didReceiveNotificationResponse:notificationResponseWithUserInfo(userInfo)
                                       withCompletionHandler:^{
                                           [exp fulfill];
                                       }];
                    [XCTWaiter waitForExpectations:@[exp] timeout:5];

                });

                it(@"should NOT call trackInternalCustomEvent on MobileEngage when V3 is not turned on", ^{
                    NSString *eventName = @"testEventName";
                    NSDictionary *payload = @{@"key1": @"value1", @"key2": @"value2", @"key3": @"value3"};
                    [MEExperimental reset];
                    MobileEngageInternal *mobileEngage = [MobileEngageInternal mock];

                    MEUserNotificationDelegate *userNotification = [[MEUserNotificationDelegate alloc] initWithApplication:[UIApplication mock] mobileEngageInternal:mobileEngage inApp:[MEInApp nullMock]];
                    NSDictionary *userInfo = @{@"ems": @{
                        @"actions": @[
                            @{
                                @"id": @"uniqueId",
                                @"title": @"actionTitle",
                                @"type": @"MECustomEvent",
                                @"name": eventName,
                                @"payload": payload
                            }
                        ]}};
                    [[mobileEngage should] receive:@selector(trackMessageOpenWithUserInfo:)];
                    [[mobileEngage should] receive:@selector(trackCustomEvent:eventAttributes:)];
                    [[mobileEngage shouldNot] receive:@selector(trackInternalCustomEvent:eventAttributes:) withArguments:eventName, payload];

                    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                    [userNotification userNotificationCenter:nil
                              didReceiveNotificationResponse:notificationResponseWithUserInfo(userInfo)
                                       withCompletionHandler:^{
                                           [exp fulfill];
                                       }];
                    [XCTWaiter waitForExpectations:@[exp] timeout:5];

                });

                it(@"should call trackInternalCustomEvent on MobileEngage with richNotification:actionClicked eventName and title and action id in the payload", ^{
                    [MEExperimental enableFeature:INAPP_MESSAGING];
                    MobileEngageInternal *mobileEngage = [MobileEngageInternal nullMock];
                    MEUserNotificationDelegate *userNotification = [[MEUserNotificationDelegate alloc] initWithApplication:[UIApplication mock] mobileEngageInternal:mobileEngage inApp:[MEInApp nullMock]];
                    NSDictionary *userInfo = @{@"ems": @{
                        @"actions": @[
                            @{
                                @"id": @"uniqueId",
                                @"title": @"actionTitle",
                                @"key": @"value"
                            }
                        ]}};
                    [[mobileEngage should] receive:@selector(trackInternalCustomEvent:eventAttributes:) withArguments:@"richNotification:actionClicked", @{
                        @"button_id": @"uniqueId",
                        @"title": @"actionTitle"
                    }];

                    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                    [userNotification userNotificationCenter:nil
                              didReceiveNotificationResponse:notificationResponseWithUserInfo(userInfo)
                                       withCompletionHandler:^{
                                           [exp fulfill];
                                       }];
                    [XCTWaiter waitForExpectations:@[exp] timeout:5];

                });

                it(@"should call mobileEngage with the correct action", ^{
                    MobileEngageInternal *mockMEInternal = [MobileEngageInternal nullMock];
                    MEUserNotificationDelegate *userNotification = [[MEUserNotificationDelegate alloc] initWithApplication:[UIApplication mock] mobileEngageInternal:mockMEInternal inApp:[MEInApp nullMock]];

                    NSDictionary *payload = @{@"key1": @"value1", @"key2": @"value2", @"key3": @"value3"};
                    NSString *eventName = @"eventName";
                    NSDictionary *userInfo = @{@"ems": @{@"actions": @[
                        @{
                            @"id": @"uniqueId",
                            @"title": @"actionTitle",
                            @"type": @"OpenExternalUrl",
                            @"url": @"https://www.emarsys.com"
                        }, @{
                            @"id": @"uniqueId2",
                            @"title": @"actionTitle",
                            @"type": @"MECustomEvent",
                            @"name": eventName,
                            @"payload": payload
                        }
                    ]}};

                    [[mockMEInternal should] receive:@selector(trackCustomEvent:eventAttributes:) withArguments:eventName, payload];

                    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                    [userNotification userNotificationCenter:nil
                              didReceiveNotificationResponse:notificationResponseWithUserInfoWithActionId(userInfo, @"uniqueId2")
                                       withCompletionHandler:^{
                                           [exp fulfill];
                                       }];
                    [XCTWaiter waitForExpectations:@[exp] timeout:5];

                });

                it(@"should call trackMessageOpenWithUserInfo on MobileEngage with the userInfo when didReceiveNotificationResponse:withCompletionHandler: is called", ^{
                    MobileEngageInternal *mobileEngage = [MobileEngageInternal nullMock];

                    MEUserNotificationDelegate *notificationDelegate = [[MEUserNotificationDelegate alloc] initWithApplication:[UIApplication mock] mobileEngageInternal:mobileEngage inApp:[MEInApp nullMock]];
                    NSDictionary *userInfo = @{@"ems": @{
                        @"u": @{
                            @"sid": @"123456789"
                        }}};
                    [[mobileEngage should] receive:@selector(trackMessageOpenWithUserInfo:) withArguments:userInfo];

                    XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                    [notificationDelegate userNotificationCenter:nil
                                  didReceiveNotificationResponse:notificationResponseWithUserInfo(userInfo)
                                           withCompletionHandler:^{
                                               [exp fulfill];
                                           }];
                    [XCTWaiter waitForExpectations:@[exp] timeout:5];

                });

                if (@available(iOS 10.0, *)) {
                    it(@"should call openURL:options:completionHandler: with the defined url if the action is type of OpenExternalUrl", ^{
                        UIApplication *application = [UIApplication mock];
                        [[application should] receive:@selector(openURL:options:completionHandler:) withArguments:[NSURL URLWithString:@"https://www.emarsys.com"], @{}, kw_any()];

                        MEUserNotificationDelegate *userNotification = [[MEUserNotificationDelegate alloc] initWithApplication:application mobileEngageInternal:[MobileEngageInternal nullMock] inApp:[MEInApp nullMock]];
                        NSDictionary *userInfo = @{@"ems": @{@"actions": @[
                            @{
                                @"id": @"uniqueId",
                                @"title": @"actionTitle",
                                @"type": @"OpenExternalUrl",
                                @"url": @"https://www.emarsys.com"
                            }
                        ]}};

                        XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                        [userNotification userNotificationCenter:nil
                                  didReceiveNotificationResponse:notificationResponseWithUserInfo(userInfo)
                                           withCompletionHandler:^{
                                               [exp fulfill];
                                           }];
                        [XCTWaiter waitForExpectations:@[exp] timeout:5];
                    });
                }

            });


            it(@"should call showMessage:completionHandler: on IAM with InAppMessage when didReceiveNotificationResponse:withCompletionHandler: is called with inApp payload", ^{
                NSObject <MEIAMProtocol> *inApp = [MEInApp mock];

                MEInAppMessage *inAppMessage = [[MEInAppMessage alloc] initWithCampaignId:@"42" html:@"<html/>"];
                KWCaptureSpy *messageSpy = [inApp captureArgument:@selector(showMessage:completionHandler:) atIndex:0];
//                [[inApp should] receive:@selector(showMessage:completionHandler:) withArguments:inAppMessage, nil];
                MEUserNotificationDelegate *notificationDelegate = [[MEUserNotificationDelegate alloc] initWithApplication:[UIApplication mock]
                                                                                                      mobileEngageInternal:[MobileEngageInternal nullMock]
                                                                                                                     inApp:inApp];
                NSDictionary *userInfo = @{@"ems": @{
                    @"inapp": @{
                        @"campaign_id": @"42",
                        @"inAppData": [@"<html/>" dataUsingEncoding:NSUTF8StringEncoding]
                    }}};

                XCTestExpectation *exp = [[XCTestExpectation alloc] initWithDescription:@"waitForResult"];
                [notificationDelegate userNotificationCenter:nil
                              didReceiveNotificationResponse:notificationResponseWithUserInfo(userInfo)
                                       withCompletionHandler:^{
                                           [exp fulfill];
                                       }];
                [XCTWaiter waitForExpectations:@[exp] timeout:5];
                MEInAppMessage *message = [messageSpy argument];
                [[message.campaignId should] equal:@"42"];
                [[message.html should] equal:@"<html/>"];
            });
        }

SPEC_END