//
//  ViewController.m
//  NetworkTest
//
//  Created by Brett Lamy on 9/26/12.
//  Copyright (c) 2012 Brett Lamy. All rights reserved.
//

#import "ViewController.h"
#import "ASIHTTPRequest.h"
#import "FSNConnection.h"
#import "MKNetworkOperation.h"
#import "MKNetworkEngine.h"
#import "AFNetworking/AFURLConnectionOperation.h"


/* These are random files from another host */
//#define kFileToBeDownloaded [NSURL URLWithString:@"http://download.thinkbroadband.com/100MB.zip"]
//#define kFileToBeDownloaded [NSURL URLWithString:@"http://download.thinkbroadband.com/512MB.zip"]
#define kFileToBeDownloaded [NSURL URLWithString:@"http://download.thinkbroadband.com/1GB.zip"]


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@end

@implementation ViewController
/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
#pragma mark - ASIHTTPRequest
/////////////////////////////////////////////////////////////////////////////////
- (IBAction)didTapStartASI:(id)sender
{
    __unsafe_unretained ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:kFileToBeDownloaded];
    [request setCompletionBlock:^{
        NSLog(@"didFinishASI");
    }];
    [request setFailedBlock:^{
        NSLog(@"didFailASI: %@", [request error]);
    }];
    [request setBytesReceivedBlock:^(unsigned long long size, unsigned long long total){
        NSLog(@"ASI downloading: %f", (float)size/(float)total);
    }];
    request.downloadProgressDelegate = self.progress;
    [request startAsynchronous];
}


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
#pragma FSNetwork
/////////////////////////////////////////////////////////////////////////////////
- (IBAction)didTapStartFSN:(id)sender
{
    FSNConnection *connection =
    [FSNConnection withUrl:kFileToBeDownloaded
                    method:FSNRequestMethodGET
                   headers:nil
                parameters:nil
                parseBlock:^id(FSNConnection *c, NSError **error) {
                    return [c.responseData dictionaryFromJSONWithError:error];
                }
           completionBlock:^(FSNConnection *c) {
               if (c.error)
                   NSLog(@"FS Failed %@", c.error);
               else
                   NSLog(@"FS Finished");
           }
             progressBlock:^(FSNConnection *c) {
                 self.progress.progress = c.downloadProgress;
                 NSLog(@"FS progress: %f", c.downloadProgress);
             }];
    
    [connection start];
}


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
#pragma MKNetwork
/////////////////////////////////////////////////////////////////////////////////
- (IBAction)didTapStartMKN:(id)sender
{
    MKNetworkEngine *operation = [[MKNetworkEngine alloc] init];
    MKNetworkOperation *op = [operation operationWithURLString:[kFileToBeDownloaded absoluteString]
                                                        params:nil
                                                    httpMethod:@"GET"];
    
    [op onUploadProgressChanged:^(double progress) {
        NSLog(@"MK downloading: %f", progress*100.0);
        self.progress.progress = progress;
    }];
    
    [op onCompletion:^(MKNetworkOperation *completedOP)
     {
         NSLog(@"Dif finish MK");
     }
             onError:^(NSError *error)
     {
         NSLog(@"didFailMK: %@", error);
     }];
    
    [operation enqueueOperation:op];
}


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
#pragma AFNetwork
/////////////////////////////////////////////////////////////////////////////////
- (IBAction)didTapStartAFN:(id)sender
{
    AFURLConnectionOperation *operation = [[AFURLConnectionOperation alloc] initWithRequest:[NSURLRequest requestWithURL:kFileToBeDownloaded]];
    [operation setCompletionBlock:^{
        if (operation.error)
            NSLog(@"AFN Failed %@", operation.error);
        else
            NSLog(@"Did finish AFN");
    }];
    
    [operation setDownloadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite)
    {
        NSLog(@"AFN Downloading: %f", (float)totalBytesWritten/(float)totalBytesExpectedToWrite);
        self.progress.progress = (float)totalBytesWritten/(float)totalBytesExpectedToWrite;
    }];
    [operation start];
}


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
#pragma NSURLConnection
/* didn't make these properties just to keep all NSURL crap in one spot */
static long long length;    
static long long downloaded;
/////////////////////////////////////////////////////////////////////////////////
- (IBAction)didTapStartNSURLConn:(id)sender
{
    length = 0;
    downloaded = 0;
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:kFileToBeDownloaded];
    NSURLConnection *theConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    [theConnection start];
}

/////////////////////////////////////////////////////////////////////////////////
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
    NSLog(@"headers %@", headers);
    length = [headers[@"Content-Length"] longLongValue];
}

/////////////////////////////////////////////////////////////////////////////////
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    downloaded += [data length];
    self.progress.progress = (float)downloaded/(float)length;
    NSLog(@"NSURLConnection Downloading %f", self.progress.progress);
}

/////////////////////////////////////////////////////////////////////////////////
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"NSURLRequest Finished");
}

/////////////////////////////////////////////////////////////////////////////////
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"NSURLRequest Failed:%@", error);
}


/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
#pragma View LifeCycle
/////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

/////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
