//
//  ViewController.m
//  ChatApp
//
//  Created by Paul Kovalenko on 05.02.14.
//  Copyright (c) 2014 Paul Kovalenko. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    __weak IBOutlet UITextField *_chatBox;
    
    __weak IBOutlet UITextView *_textBox;
    
    MCBrowserViewController *_browserVC;
    
    MCAdvertiserAssistant *_advertiser;
    
    MCSession *_mySession;
    
    MCPeerID *_myPeerID;
}

- (IBAction) inviteButtonTouchUpInside:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [_textBox.layer setCornerRadius:5];

    [self setupMultipeer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(openBrowserWithDelay)
                                                 name:@"NOTIFICATION_OPEN_BROWSER"
                                               object:nil];
}

- (void) openBrowserWithDelay
{
    [self performSelector:@selector(appearBrowser) withObject:nil afterDelay:0.5];
}

- (void) appearBrowser
{
    if (self.presentedViewController == nil && ![self.presentedViewController isKindOfClass:[MCBrowserViewController class]]) {
        [self presentViewController:_browserVC animated:YES completion:nil];
    }
}

- (void) setupMultipeer
{
    _myPeerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];
    
    _mySession = [[MCSession alloc] initWithPeer:_myPeerID];
    _mySession.delegate = self;
    
    _browserVC = [[MCBrowserViewController alloc] initWithServiceType:@"chat" session:_mySession];
    _browserVC.delegate = self;
    
    _advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:@"chat" discoveryInfo:nil session:_mySession];
    [_advertiser start];
}

- (void) receiveMessage: (NSString *) message fromPeer: (MCPeerID *) peer{
    
    NSString *finalText;
    if (peer == _myPeerID) {
        finalText = [NSString stringWithFormat:@"\nme: %@ \n", message];
    }
    else{
        finalText = [NSString stringWithFormat:@"\n%@: %@ \n", peer.displayName, message];
    }
    
    _textBox.text = [_textBox.text stringByAppendingString:finalText];
}

#pragma marks MCBrowserViewControllerDelegate

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController{
    [self dismissBrowserVC];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController{
    [self dismissBrowserVC];
}

#pragma marks MCSessionDelegate
// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    
}

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
    //  Decode data back to NSString
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    //  append message to text box:
    dispatch_async(dispatch_get_main_queue(), ^{
        [self receiveMessage:message fromPeer:peerID];
    });
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
    
}

#pragma mark - textField

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    [self sendText];
    
    return YES;
}

- (void) dismissBrowserVC{
    [_browserVC dismissViewControllerAnimated:YES completion:nil];
}

- (void) sendText{
    NSString *message = _chatBox.text;
    _chatBox.text = @"";
    
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    [_mySession sendData:data toPeers:[_mySession connectedPeers] withMode:MCSessionSendDataUnreliable error:&error];
    
    [self receiveMessage: message fromPeer:_myPeerID];
}

- (NSURL *) fileToURL:(NSString*)filename
{
    NSArray *fileComponents = [filename componentsSeparatedByString:@"."];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:[fileComponents objectAtIndex:0] ofType:[fileComponents objectAtIndex:1]];
    
    return [NSURL fileURLWithPath:filePath];
}

- (IBAction) inviteButtonTouchUpInside:(id)sender
{
    NSURL *url = [self fileToURL:@"PostScript.ps"];
    NSArray *objectsToShare = @[url];
    
    UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    NSArray *excludedActivities = @[UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
                                    UIActivityTypePostToWeibo,
                                    UIActivityTypeMessage, UIActivityTypeMail,
                                    UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                                    UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,
                                    UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
        controller.excludedActivityTypes = excludedActivities;
    
    [self presentViewController:controller animated:YES completion:nil];
}

#pragma mark - memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
