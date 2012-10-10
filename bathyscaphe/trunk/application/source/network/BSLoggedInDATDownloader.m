//
//  BSLoggedInDATDownloader.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/10/15.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//

#import "BSLoggedInDATDownloader.h"
#import "ThreadTextDownloader_p.h"
#import "AppDefaults.h"
#import "w2chConnect.h"

static NSString *const kResourceURLTemplate = @"http://%@/test/offlaw.cgi%@/%@/?raw=0.0&sid=%@";

@implementation BSLoggedInDATDownloader
- (id)initWithIdentifier:(CMRThreadSignature *)signature threadTitle:(NSString *)aTitle candidateHost:(NSString *)host
{
    if (self = [super init]) {
        [self setReusesDownloader:NO];
        [self setCandidateHost:host];
        [self setNextIndex:0];
        [self setIdentifier:signature];
        [self setThreadTitle:aTitle];
        if (![self updateSessionID]) {
            [self autorelease];
            return nil;
        }
    }
    return self;
}

+ (id)downloaderWithIdentifier:(CMRThreadSignature *)signature threadTitle:(NSString *)aTitle candidateHost:(NSString *)host
{
    return [[[self alloc] initWithIdentifier:signature threadTitle:aTitle candidateHost:host] autorelease];
}

- (BOOL)updateSessionID
{
    id<w2chAuthenticationStatus>    authenticator_;
    NSString                        *sessionID_;

    authenticator_ = [CMRPref shared2chAuthenticator];
    if (!authenticator_) return NO;

    sessionID_ = [authenticator_ sessionID];

    if (sessionID_) {
        m_sessionID = [sessionID_ retain];
    } else if ([authenticator_ recentErrorType] != w2chNoError) {
        [m_sessionID release];
        m_sessionID = nil;
        return NO;
    }
    
    return YES;
}

- (NSString *)sessionID
{
    return m_sessionID;
}

- (NSString *)downloadingHost
{
    if (!m_downloadingHost) {
        m_downloadingHost = [[[self boardURL] host] retain];
    }
    return m_downloadingHost;
}

- (void)setDownloadingHost:(NSString *)host
{
    [host retain];
    [m_downloadingHost release];
    m_downloadingHost = host;
}

- (NSString *)candidateHost
{
    return m_candidateHost;
}

- (void)setCandidateHost:(NSString *)host
{
    [host retain];
    [m_candidateHost release];
    m_candidateHost = host;
}

- (BOOL)reusesDownloader
{
    return m_reuse;
}

- (void)setReusesDownloader:(BOOL)willReuse
{
    m_reuse = willReuse;
}

- (void)dealloc
{
    [self setCandidateHost:nil];
    [self setDownloadingHost:nil];
    [m_sessionID release];
    [super dealloc];
}

- (NSURL *)resourceURL
{
    if(![self sessionID]) {
        return [super resourceURL];
    }
    NSString *sidEscaped = [[self sessionID] stringByURLEncodingUsingEncoding:NSASCIIStringEncoding];

// #warning 64BIT: Check formatting arguments
// 2010-03-27 tsawada2 検証済
    return [NSURL URLWithString:[NSString stringWithFormat:kResourceURLTemplate,
                                    [self downloadingHost], [[self boardURL] path], [[self threadSignature] identifier], sidEscaped]];
}

- (BOOL)useMaru
{
    return ([self sessionID] != nil);
}

- (void)cancelDownloadWithDetectingDatOchi
{
    if (![self candidateHost]) {
        NSArray			*recoveryOptions;
        NSDictionary	*dict;
        NSError			*error;
        NSString *description;
        NSString *suggestion;
        description = [self localizedString:@"MaruFailDescription"];
        suggestion = [self localizedString:@"MaruFailSuggestion"];

        recoveryOptions = [NSArray arrayWithObjects:[self localizedString:@"ErrorRecoveryCancel"], nil];
        dict = [NSDictionary dictionaryWithObjectsAndKeys:
                recoveryOptions, NSLocalizedRecoveryOptionsErrorKey,
                description, NSLocalizedDescriptionKey,
                suggestion, NSLocalizedRecoverySuggestionErrorKey,
                NULL];
        error = [NSError errorWithDomain:BSBathyScapheErrorDomain code:BSLoggedInDATDownloaderThreadNotFoundError userInfo:dict];
        UTILNotifyInfo3(CMRDATDownloaderDidDetectDatOchiNotification, error, @"Error");
        return;
    }
    [[CMRNetGrobalLock sharedInstance] remove:[self resourceURL]];
    [self setReusesDownloader:YES];
    [self setDownloadingHost:[self candidateHost]];
    [self setCandidateHost:nil]; // 今はこうしておかないと、万一移転前サーバにも見つからなかったときに無限再挑戦してしまう
}
@end
