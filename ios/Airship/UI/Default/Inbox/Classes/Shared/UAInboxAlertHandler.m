/*
 Copyright 2009-2015 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC ``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "UACommon.h"

#import "UAInboxAlertHandler.h"
#import "UAInboxLocalization.h"

UA_SUPPRESS_UI_DEPRECATION_WARNINGS

@interface UAInboxAlertHandler()
@property(nonatomic, copy) UAInboxAlertHandlerViewBlock viewBlock;
@end

@implementation UAInboxAlertHandler

- (instancetype)init {
    self = [super init];
    if (self) {

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)enterBackground {
    [self.notificationAlert dismissWithClickedButtonIndex:0 animated:NO];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        self.viewBlock();
    }

    self.notificationAlert = nil;
}

- (void)showNewMessageAlert:(NSString *)message withViewBlock:(UAInboxAlertHandlerViewBlock)viewBlock {
    self.viewBlock = viewBlock;
    /* In the event that one happens to be showing. (These are no-ops if notificationAlert is nil.) */
    [self.notificationAlert dismissWithClickedButtonIndex:0 animated:NO];
    self.notificationAlert = nil;

    /* display a new alert */
    self.notificationAlert = [[UIAlertView alloc] initWithTitle:UAInboxLocalizedString(@"UA_New_Message_Available_Title")
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:UAInboxLocalizedString(@"UA_OK")
                                              otherButtonTitles:UAInboxLocalizedString(@"UA_View"),
                              nil];
    [self.notificationAlert show];

}

@end
