//
//  BSURLDownload.m
//  BathyScaphe
//
//  Created by Tsutomu Sawada on 07/10/27.
//  Copyright 2007-2010 BathyScaphe Project. All rights reserved.
//  encoding="UTF-8"
//

#import "BSURLDownload.h"

@interface BSURLDownload(Private)
- (void)setURL:(NSURL *)url;
- (void)setDestination:(NSString *)destination;
- (void)setDownloadedFilePath:(NSString *)path;

- (BOOL)delegateRespondsTo:(SEL)selector;
@end


@implementation BSURLDownload(Private)
- (void)setURL:(NSURL *)url
{
	[url retain];
	[m_targetURL release];
	m_targetURL = url;
}

- (void)setDestination:(NSString *)destination
{
	[destination retain];
	[m_destination release];
	m_destination = destination;
}

- (void)setDownloadedFilePath:(NSString *)path
{
	[path retain];
	[m_downloadedFilePath release];
	m_downloadedFilePath = path;
}

- (BOOL)delegateRespondsTo:(SEL)selector
{
	id delegate = [self delegate];
	return (delegate && [delegate respondsToSelector:selector]);
}
@end


@implementation BSURLDownload
- (id)initWithURL:(NSURL *)url delegate:(id)delegate destination:(NSString *)path
{
	if (self = [super init]) {
		[self setURL:url];
		[self setDelegate:delegate];
		[self setDestination:path];
		[self setAllowsOverwriteDownloadedFile:NO];

		NSURLRequest *request = [NSURLRequest requestWithURL:url];
		m_download  = [[NSURLDownload alloc] initWithRequest:request delegate:self];
	}
	return self;
}

- (void)dealloc
{
	[m_download release];
	m_download = nil;

	[self setDestination:nil];
	[self setDownloadedFilePath:nil];
	[self setDelegate:nil];
	[self setURL:nil];
	
	[super dealloc];
}

- (NSURL *)URL
{
	return m_targetURL;
}

- (NSURLDownload *)URLDownload
{
	return m_download;
}

- (NSString *)destination
{
	return m_destination;
}

- (NSString *)downloadedFilePath
{
	return m_downloadedFilePath;
}

- (void)cancel
{
	[[self URLDownload] cancel];
}

- (id)delegate
{
	return m_delegate;
}

- (void)setDelegate:(id)delegate
{
	m_delegate = delegate;
}

- (BOOL)allowsOverwriteDownloadedFile
{
	return m_allowsOverwrite;
}

- (void)setAllowsOverwriteDownloadedFile:(BOOL)flag
{
	m_allowsOverwrite = flag;
}

#pragma mark NSURLDownload Delegate
- (void)download:(NSURLDownload *)dl didReceiveResponse:(NSURLResponse *)response
{
	lExLength = [response expectedContentLength];
	lDlLength = 0;

    if ([self delegateRespondsTo:@selector(bsURLDownload:shouldDownloadWithMIMEType:)]) {
        BOOL shouldContinue = [[self delegate] bsURLDownload:self shouldDownloadWithMIMEType:[response MIMEType]];
        if (!shouldContinue) {
            [dl cancel];
			if ([self delegateRespondsTo:@selector(bsURLDownloadDidAbortForDenyingResponsedMIMEType:)]) {
				[[self delegate] bsURLDownloadDidAbortForDenyingResponsedMIMEType:self];
			} else {
				[dl release];
			}
            return;
        }
    }

	if (lExLength != NSURLResponseUnknownLength) {
		if ([self delegateRespondsTo:@selector(bsURLDownload:willDownloadContentOfSize:)]) {
            NSNumber *tmp = [[NSNumber alloc] initWithLongLong:lExLength];
            NSUInteger expectedLength = [tmp unsignedIntegerValue];
            [tmp release];
			[[self delegate] bsURLDownload:self willDownloadContentOfSize:expectedLength];
		}
	}
}

- (NSURLRequest *)download:(NSURLDownload *)dl willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
	// Leopard
	if (!redirectResponse) return request;

	if ([self delegateRespondsTo:@selector(bsURLDownload:shouldRedirectToURL:)]) {
		NSURL	*newURL = [[request URL] retain];
		BOOL	shouldContinue = [[self delegate] bsURLDownload:self shouldRedirectToURL:newURL];
		if (!shouldContinue) {
			[dl cancel];
			if ([self delegateRespondsTo:@selector(bsURLDownload:didAbortRedirectionToURL:)]) {
				[[self delegate] bsURLDownload:self didAbortRedirectionToURL:newURL];
			} else {
				[dl release];
			}
		}
		[newURL release];
	}
	return request;
}

- (void)download:(NSURLDownload *)dl decideDestinationWithSuggestedFilename:(NSString *)filename
{
    if ([self delegateRespondsTo:@selector(bsURLDownload:shouldDownloadWithDestinationFileName:)]) {
        BOOL shouldContinue = [[self delegate] bsURLDownload:self shouldDownloadWithDestinationFileName:filename];
        if (!shouldContinue) {
            [dl cancel];
            if ([self delegateRespondsTo:@selector(bsURLDownloadDidAbortForDenyingSuggestedFileName:)]) {
                [[self delegate] bsURLDownloadDidAbortForDenyingSuggestedFileName:self];
            } else {
                [dl release];
            }
            return;
        }
    }
	NSString *savePath;
	savePath = [[self destination] stringByAppendingPathComponent:filename];

	[dl setDestination:savePath allowOverwrite:[self allowsOverwriteDownloadedFile]];
}

- (void)download:(NSURLDownload *)dl didCreateDestination:(NSString *)asDstPath
{
	[self setDownloadedFilePath:asDstPath];
}

- (void)download:(NSURLDownload *)dl didReceiveDataOfLength:(NSUInteger)len
{
	lDlLength += len;

	if (lExLength != NSURLResponseUnknownLength) {
		if ([self delegateRespondsTo:@selector(bsURLDownload:didDownloadContentOfSize:)]) {
			[[self delegate] bsURLDownload:self didDownloadContentOfSize:lDlLength];
		}
	}
}

- (void)downloadDidFinish:(NSURLDownload *)dl
{
	if ([self delegateRespondsTo:@selector(bsURLDownloadDidFinish:)]) {
		[[self delegate] bsURLDownloadDidFinish:self];
	} else {
		[dl release];
	}
}

- (void)download:(NSURLDownload *)dl didFailWithError:(NSError *)error
{
	if ([self delegateRespondsTo:@selector(bsURLDownload:didFailWithError:)]) {
		[[self delegate] bsURLDownload:self didFailWithError:error];
	} else {
		[dl release];
	}
}
@end
