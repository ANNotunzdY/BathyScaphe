//
//  TrustedApplication.m
//  Keychain
//
//  Created by Wade Tregaskis on Fri Jan 24 2003.
//
//  Copyright (c) 2003, Wade Tregaskis.  All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "TrustedApplication.h"


@implementation TrustedApplication

+ (TrustedApplication*)trustedApplicationWithPath:(NSString*)path {
    return [[[[self class] alloc] initWithPath:path] autorelease];
}

+ (TrustedApplication*)trustedApplicationWithTrustedApplicationRef:(SecTrustedApplicationRef)trustedApp {
    return [[[[self class] alloc] initWithTrustedApplicationRef:trustedApp] autorelease];
}

- (TrustedApplication*)initWithPath:(NSString*)path {
    error = SecTrustedApplicationCreateFromPath((path ? [path cString] : NULL), &trustedApplication);

    if (error == 0) {
        self = [super init];
        
        return self;
    } else {
        [self release];
        
        return nil;
    }
}

- (TrustedApplication*)initWithTrustedApplicationRef:(SecTrustedApplicationRef)trustedApp {
    TrustedApplication *existingObject;
    
    if (trustedApp) {
        existingObject = [[self class] instanceWithKey:(id)trustedApp from:@selector(trustedApplicationRef) simpleKey:NO];

        if (existingObject) {
            [self release];

            return [existingObject retain];
        } else {
            if (self = [super init]) {
                CFRetain(trustedApp);
                trustedApplication = trustedApp;
            }

            return self;
        }
    } else {
        [self release];

        return nil;
    }
}

- (TrustedApplication*)init {
    return [self initWithPath:nil];
}

- (void)setData:(NSData*)data {
    error = SecTrustedApplicationSetData(trustedApplication, (CFDataRef)data);
}

- (NSData*)data {
    CFDataRef result;

    error = SecTrustedApplicationCopyData(trustedApplication, &result);

    if (error == 0) {
        return [(NSData*)result autorelease];
    } else {
        return nil;
    }
}

- (int)lastError {
    return error;
}

- (SecTrustedApplicationRef)trustedApplicationRef {
    return trustedApplication;
}

- (void)dealloc {
    if (trustedApplication) {
        CFRelease(trustedApplication);
    }
    
    [super dealloc];
}

@end
