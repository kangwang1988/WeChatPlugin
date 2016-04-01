//
//  NKWeChatPlugin.m
//  CLPDemo
//
//  Created by KyleWong on 3/28/16.
//  Copyright © 2016 KyleWong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import "NKWCUtil.h"

NSString *kKeyDefaultsAutoOpenRedEnvelopEnabled = @"kKeyDefaultsAutoOpenRedEnvelopEnabled";
NSString *kKeyPluginInfoAutoOpenMsg = @"kKeyPluginInfoAutoOpenMsg";
NSString *kKeyPluginInfoAutoOpenRedEnvelop = @"kKeyPluginInfoAutoOpenRedEnvelop";
NSString *kKeyPluginInfoAutoCloseRedEnvelopDetail = @"kKeyPluginInfoAutoCloseRedEnvelopDetail";
static NSMutableDictionary *sRedEnvelopInfoDict = nil;
static NSMutableArray *sRedEnvelopNodeViewArray = nil;
static char kKeyObjcAssociateMsgId;
static NSMutableString *sAutoOpeningMsgSrvId = nil;

@interface NKWeChatPlugin : NSObject<UIAlertViewDelegate>
+ (void)injectAutoOpenRedMsgCode;
+ (void)injectAutoOpenRedEnvelopCode;
+ (void)injectAutoCloseRedEnvelopCode;
+ (void)runAutoOpenCheck;
+ (BOOL)autoOpenRedEnvelopEnabled;
+ (void)setAutoOpenRedEnvelopEnabled:(BOOL)autoOpenRedEnvelopEnabled;
+ (NSString *)autoOpeningMsgSrvId;
+ (void)setAutoOpeningMsgSrvId:(NSString *)aAutoOpeningMsgSrvId;
+ (void)onShowAutoOpenRedEnvelopSettings:(UITapGestureRecognizer *)aTapRecognizer;
+ (NSString *)extractMsgIdByNodeView:(id)aNodeView;
+ (NSString *)extractMsgIdByWrap:(id)aMsgWrap withKey:(NSString *)aKey;
+ (NSString *)extractMsgIdByControlData:(id)aControlData withKey:(NSString *)aKey;
@end

__attribute__((constructor))
static void dylibRuntimeInjection() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [NKWeChatPlugin injectAutoOpenRedMsgCode];
        [NKWeChatPlugin injectAutoOpenRedEnvelopCode];
        [NKWeChatPlugin injectAutoCloseRedEnvelopCode];
        sRedEnvelopInfoDict = [[NSMutableDictionary alloc] init];
        sRedEnvelopNodeViewArray = [[NSMutableArray alloc] init];
        sAutoOpeningMsgSrvId = [[NSMutableString alloc] init];
        
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:[NKWeChatPlugin class] action:@selector(onShowAutoOpenRedEnvelopSettings:)];
        [gestureRecognizer setNumberOfTapsRequired:5];
        [window addGestureRecognizer:gestureRecognizer];
    });
}

#pragma mark --- RedEnvelopMsg
UIKIT_STATIC_INLINE void nk_WCPayC2CMessageNodeView_didMoveToSuperview(id self, SEL _cmd){
    if([NKWeChatPlugin autoOpenRedEnvelopEnabled]){
        NSString *selfMesSvrId = [NKWeChatPlugin extractMsgIdByNodeView:self];
        for(NSInteger idx = 0;idx!=sRedEnvelopNodeViewArray.count;idx++){
            id nodeView = [sRedEnvelopNodeViewArray objectAtIndex:idx];
            if([selfMesSvrId isEqualToString:[NKWeChatPlugin extractMsgIdByNodeView:nodeView]]){
                [sRedEnvelopNodeViewArray removeObject:nodeView];
                idx--;
            }
        }
        if([selfMesSvrId isEqualToString:[NKWeChatPlugin autoOpeningMsgSrvId]]){
            [sRedEnvelopInfoDict removeObjectForKey:[NKWCUtil stringByEnsuringNotNil:selfMesSvrId]];
            [NKWeChatPlugin setAutoOpeningMsgSrvId:nil];
        }
        if(![sRedEnvelopNodeViewArray containsObject:self]){
            [sRedEnvelopNodeViewArray addObject:self];
        }
        [NKWeChatPlugin runAutoOpenCheck];
    }
    ((id (*)(id,SEL))objc_msgSend)(self,NSSelectorFromString(@"nk_WCPayC2CMessageNodeView_didMoveToSuperview"));
}

#pragma mark --- RedEnvelopHomeView
UIKIT_STATIC_INLINE void nk_WCRedEnvelopesReceiveHomeView_initWithFrame_andData_delegate(id self, SEL _cmd,struct CGRect rect,id data,id  delegate){
    NSString *key = [NKWCUtil stringByEnsuringNotNil:[NKWeChatPlugin extractMsgIdByControlData:data withKey:@"m_ui64MesSvrID"]];
    objc_setAssociatedObject(self, &kKeyObjcAssociateMsgId, key, OBJC_ASSOCIATION_COPY);
    [NKWCUtil log:@"[KWLM1]-%@-%@-%@-%@-%@-%@",self,NSStringFromSelector(_cmd),NSStringFromCGRect(rect),data,delegate,key];
    ((id (*)(id,SEL,struct CGRect,id,id))objc_msgSend)(self,NSSelectorFromString(@"nk_WCRedEnvelopesReceiveHomeView_initWithFrame:andData:delegate:"),rect,data,delegate);
}

UIKIT_STATIC_INLINE void nk_WCRedEnvelopesReceiveHomeView_didMoveToSuperview(id self, SEL _cmd){
    if([NKWeChatPlugin autoOpenRedEnvelopEnabled]){
        NSString *key = objc_getAssociatedObject(self, &kKeyObjcAssociateMsgId);
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[sRedEnvelopInfoDict objectForKey:[NKWCUtil stringByEnsuringNotNil:key]]];
        if(![[dict objectForKey:kKeyPluginInfoAutoOpenRedEnvelop] boolValue]){
            [NKWCUtil log:@"[KWLM2]-%@-%@-%@-%@",self,NSStringFromSelector(_cmd),key,dict];
            [dict setObject:@(1) forKey:kKeyPluginInfoAutoOpenRedEnvelop];
            [sRedEnvelopInfoDict setObject:dict forKey:key];
            [self performSelector:NSSelectorFromString(@"OnOpenRedEnvelopes") withObject:nil afterDelay:.5f];
        }
    }
    ((id (*)(id,SEL))objc_msgSend)(self,NSSelectorFromString(@"nk_WCRedEnvelopesReceiveHomeView_didMoveToSuperview"));
}

#pragma mark --- RedEnvelopDetailController
UIKIT_STATIC_INLINE void nk_WCRedEnvelopesRedEnvelopesDetailViewController_setupWithData(id self, SEL _cmd,id data){
    NSString *key = [NKWCUtil stringByEnsuringNotNil:[NKWeChatPlugin extractMsgIdByControlData:data withKey:@"m_ui64MesSvrID"]];
    objc_setAssociatedObject(self, &kKeyObjcAssociateMsgId, key, OBJC_ASSOCIATION_COPY);
    [NKWCUtil log:@"[KWLM3]-%@-%@-%@-%@",self,NSStringFromSelector(_cmd),data,key];
    ((id (*)(id,SEL,id))objc_msgSend)(self,NSSelectorFromString(@"nk_WCRedEnvelopesRedEnvelopesDetailViewController_setupWithData:"),data);
}

UIKIT_STATIC_INLINE void nk_WCRedEnvelopesRedEnvelopesDetailViewController_viewDidAppear(id self, SEL _cmd,BOOL animated){
    ((id (*)(id,SEL,BOOL))objc_msgSend)(self,NSSelectorFromString(@"nk_WCRedEnvelopesRedEnvelopesDetailViewController_viewDidAppear:"),animated);
    id title = [[self valueForKeyPath:@"navigationItem.leftBarButtonItem.m_btn"] titleForState:UIControlStateNormal];
    if([title isEqualToString:@"返回"] || [title isEqualToString:@"Back"]){
        [[self navigationController] popViewControllerAnimated:YES];
        [NKWCUtil log:@"[KWLM4]-%@-%@-%@-%@",self,NSStringFromSelector(_cmd),title,[title class]];
    }
}

UIKIT_STATIC_INLINE void nk_WCRedEnvelopesRedEnvelopesDetailViewController_viewDidDisappear(id self, SEL _cmd,BOOL animated){
    NSString *mesSvrId = objc_getAssociatedObject(self, &kKeyObjcAssociateMsgId);
    [NKWCUtil log:@"[KWLM5]-%@-%@-%@",self,NSStringFromSelector(_cmd),mesSvrId];
    [NKWeChatPlugin setAutoOpeningMsgSrvId:nil];
    [NKWeChatPlugin runAutoOpenCheck];
    ((id (*)(id,SEL,BOOL))objc_msgSend)(self,NSSelectorFromString(@"nk_WCRedEnvelopesRedEnvelopesDetailViewController_viewDidDisappear:"),animated);
}

UIKIT_STATIC_INLINE void nk_WCRedEnvelopesRedEnvelopesDetailViewController_setLeftCloseBarButton(id self, SEL _cmd){
    if([NKWeChatPlugin autoOpenRedEnvelopEnabled]){
        NSString *key = objc_getAssociatedObject(self, &kKeyObjcAssociateMsgId);
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[sRedEnvelopInfoDict objectForKey:[NKWCUtil stringByEnsuringNotNil:key]]];
        if(![[dict objectForKey:kKeyPluginInfoAutoCloseRedEnvelopDetail] boolValue]){
            [NKWCUtil log:@"[KWLM6]-%@-%@-%@-%@",self,NSStringFromSelector(_cmd),key,dict];
            [dict setObject:@(1) forKey:kKeyPluginInfoAutoCloseRedEnvelopDetail];
            [sRedEnvelopInfoDict setObject:dict forKey:key];
            [self performSelector:NSSelectorFromString(@"OnLeftBarButtonDone") withObject:nil afterDelay:.5f];
        }
    }
    ((id (*)(id,SEL))objc_msgSend)(self,NSSelectorFromString(@"nk_WCRedEnvelopesRedEnvelopesDetailViewController_setLeftCloseBarButton"));
}

@implementation NKWeChatPlugin
+ (void)injectAutoOpenRedMsgCode{
    Class WCPayC2CMessageNodeViewClass = NSClassFromString(@"WCPayC2CMessageNodeView");
    SEL sel1 = NSSelectorFromString(@"didMoveToSuperview");
    SEL sel2 = NSSelectorFromString(@"nk_WCPayC2CMessageNodeView_didMoveToSuperview");
    Method m1 = class_getInstanceMethod(WCPayC2CMessageNodeViewClass, sel1);
    const char *typeEncode1 = method_getTypeEncoding(m1);
    class_addMethod(WCPayC2CMessageNodeViewClass,sel2,nk_WCPayC2CMessageNodeView_didMoveToSuperview,typeEncode1);
    [NKWCUtil swizzerInstanceMethod:WCPayC2CMessageNodeViewClass selector:sel1 withSelector:sel2];
}

+ (void)injectAutoOpenRedEnvelopCode{
    Class WCRedEnvelopesReceiveHomeViewClass = NSClassFromString(@"WCRedEnvelopesReceiveHomeView");
    SEL sel1 = NSSelectorFromString(@"didMoveToSuperview");
    SEL sel2 = NSSelectorFromString(@"nk_WCRedEnvelopesReceiveHomeView_didMoveToSuperview");
    Method m1 = class_getInstanceMethod(WCRedEnvelopesReceiveHomeViewClass, sel1);
    const char * typeEncode1 = method_getTypeEncoding(m1);
    class_addMethod(WCRedEnvelopesReceiveHomeViewClass,sel2,nk_WCRedEnvelopesReceiveHomeView_didMoveToSuperview,typeEncode1);
    [NKWCUtil swizzerInstanceMethod:WCRedEnvelopesReceiveHomeViewClass selector:sel1 withSelector:sel2];
    
    sel1 = NSSelectorFromString(@"initWithFrame:andData:delegate:");
    sel2 = NSSelectorFromString(@"nk_WCRedEnvelopesReceiveHomeView_initWithFrame:andData:delegate:");
    m1 = class_getInstanceMethod(WCRedEnvelopesReceiveHomeViewClass, sel1);
    typeEncode1 = method_getTypeEncoding(m1);
    class_addMethod(WCRedEnvelopesReceiveHomeViewClass,sel2,nk_WCRedEnvelopesReceiveHomeView_initWithFrame_andData_delegate,typeEncode1);
    [NKWCUtil swizzerInstanceMethod:WCRedEnvelopesReceiveHomeViewClass selector:sel1 withSelector:sel2];
}

+ (void)injectAutoCloseRedEnvelopCode{
    Class WCRedEnvelopesRedEnvelopesDetailViewControllerClass = NSClassFromString(@"WCRedEnvelopesRedEnvelopesDetailViewController");
    SEL sel1 = NSSelectorFromString(@"setupWithData:");
    SEL sel2 = NSSelectorFromString(@"nk_WCRedEnvelopesRedEnvelopesDetailViewController_setupWithData:");
    Method m1 = class_getInstanceMethod(WCRedEnvelopesRedEnvelopesDetailViewControllerClass, sel1);
    const char * typeEncode1 = method_getTypeEncoding(m1);
    class_addMethod(WCRedEnvelopesRedEnvelopesDetailViewControllerClass,sel2,nk_WCRedEnvelopesRedEnvelopesDetailViewController_setupWithData,typeEncode1);
    [NKWCUtil swizzerInstanceMethod:WCRedEnvelopesRedEnvelopesDetailViewControllerClass selector:sel1 withSelector:sel2];
    
    sel1 = NSSelectorFromString(@"viewDidAppear:");
    sel2 = NSSelectorFromString(@"nk_WCRedEnvelopesRedEnvelopesDetailViewController_viewDidAppear:");
    m1 = class_getInstanceMethod(WCRedEnvelopesRedEnvelopesDetailViewControllerClass, sel1);
    typeEncode1 = method_getTypeEncoding(m1);
    class_addMethod(WCRedEnvelopesRedEnvelopesDetailViewControllerClass,sel2,nk_WCRedEnvelopesRedEnvelopesDetailViewController_viewDidAppear,typeEncode1);
    [NKWCUtil swizzerInstanceMethod:WCRedEnvelopesRedEnvelopesDetailViewControllerClass selector:sel1 withSelector:sel2];
    
    sel1 = NSSelectorFromString(@"setLeftCloseBarButton");
    sel2 = NSSelectorFromString(@"nk_WCRedEnvelopesRedEnvelopesDetailViewController_setLeftCloseBarButton");
    m1 = class_getInstanceMethod(WCRedEnvelopesRedEnvelopesDetailViewControllerClass, sel1);
    typeEncode1 = method_getTypeEncoding(m1);
    class_addMethod(WCRedEnvelopesRedEnvelopesDetailViewControllerClass,sel2,nk_WCRedEnvelopesRedEnvelopesDetailViewController_setLeftCloseBarButton,typeEncode1);
    [NKWCUtil swizzerInstanceMethod:WCRedEnvelopesRedEnvelopesDetailViewControllerClass selector:sel1 withSelector:sel2];
    
    sel1 = NSSelectorFromString(@"viewDidDisappear:");
    sel2 = NSSelectorFromString(@"nk_WCRedEnvelopesRedEnvelopesDetailViewController_viewDidDisappear:");
    m1 = class_getInstanceMethod(WCRedEnvelopesRedEnvelopesDetailViewControllerClass, sel1);
    typeEncode1 = method_getTypeEncoding(m1);
    class_addMethod(WCRedEnvelopesRedEnvelopesDetailViewControllerClass,sel2,nk_WCRedEnvelopesRedEnvelopesDetailViewController_viewDidDisappear,typeEncode1);
    [NKWCUtil swizzerInstanceMethod:WCRedEnvelopesRedEnvelopesDetailViewControllerClass selector:sel1 withSelector:sel2];
}

+ (void)runAutoOpenCheck{
    if([self autoOpeningMsgSrvId].length){
        return;
    }
    NSInteger cnt = sRedEnvelopNodeViewArray.count;
    for(NSInteger idx = 0;idx<cnt;idx++){
        id nodeView = [sRedEnvelopNodeViewArray objectAtIndex:idx];
        if(![nodeView isKindOfClass:NSClassFromString(@"WCPayC2CMessageNodeView")]){
            continue;
        }
        NSString *mesSvrId = [NKWeChatPlugin extractMsgIdByNodeView:nodeView];
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[sRedEnvelopInfoDict objectForKey:[NKWCUtil stringByEnsuringNotNil:mesSvrId]]];
        if(![[dict objectForKey:kKeyPluginInfoAutoOpenMsg] boolValue]){
            [self setAutoOpeningMsgSrvId:mesSvrId];
            [NKWCUtil log:@"[KWLM7]-%@-%@-%@-%@",self,NSStringFromSelector(_cmd),mesSvrId,dict];
            [dict setObject:@(1) forKey:kKeyPluginInfoAutoOpenMsg];
            [sRedEnvelopInfoDict setObject:dict forKey:mesSvrId];
            [sRedEnvelopNodeViewArray removeObject:nodeView];
            [nodeView performSelector:NSSelectorFromString(@"onClick") withObject:nil afterDelay:.5f];
            break;
        }
    }
}

#pragma mark - Getter Setter for Property
+ (BOOL)autoOpenRedEnvelopEnabled{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger enabled = [[defaults objectForKey:kKeyDefaultsAutoOpenRedEnvelopEnabled] boolValue];
    return enabled;
}

+ (void)setAutoOpenRedEnvelopEnabled:(BOOL)autoOpenRedEnvelopEnabled{
    if([self autoOpenRedEnvelopEnabled] == autoOpenRedEnvelopEnabled)
        return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(autoOpenRedEnvelopEnabled) forKey:kKeyDefaultsAutoOpenRedEnvelopEnabled];
    [defaults synchronize];
    sRedEnvelopInfoDict = [[NSMutableDictionary alloc] init];
    sRedEnvelopNodeViewArray = [[NSMutableArray alloc] init];
    sAutoOpeningMsgSrvId = [[NSMutableString alloc] init];
}

+ (NSString *)autoOpeningMsgSrvId{
    return sAutoOpeningMsgSrvId;
}

+ (void)setAutoOpeningMsgSrvId:(NSString *)aAutoOpeningMsgSrvId{
    [sAutoOpeningMsgSrvId setString:[NKWCUtil stringByEnsuringNotNil:aAutoOpeningMsgSrvId]];
}

#pragma mark - Settings
+ (void)onShowAutoOpenRedEnvelopSettings:(UITapGestureRecognizer *)aTapRecognizer{
    NSString *message = @"当前自动抢红包状态为禁止，是否解禁？";
    NSString *otherTitle = @"解禁";
    if([self autoOpenRedEnvelopEnabled]){
        message = @"当前自动抢红包状态为解禁，是否禁止？";
        otherTitle = @"禁止";
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"自动抢红包设置" message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:otherTitle, nil];
    [alertView show];
}

#pragma mark - Util
+ (NSString *)extractMsgIdByNodeView:(id)aNodeView{
    if(![aNodeView isKindOfClass:NSClassFromString(@"WCPayC2CMessageNodeView")])
        return nil;
    return [NKWeChatPlugin extractMsgIdByWrap:[aNodeView valueForKeyPath:@"m_msgWrap"] withKey:@"m_ui64MesSvrID"];
}

+ (NSString *)extractMsgIdByWrap:(id)aMsgWrap withKey:(NSString *)aKey{
    NSString *description = [NSString stringWithFormat:@"%@",aMsgWrap];
    NSString *tmpStr = [description stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]];
    NSArray *keyValues = [tmpStr componentsSeparatedByString:@", "];
    NSString *numStr = nil;
    for(NSString *keyValue in keyValues){
        if([keyValue hasPrefix:[NSString stringWithFormat:@"%@=",aKey]]){
            numStr = [keyValue substringWithRange:NSMakeRange(aKey.length+1,keyValue.length-aKey.length-1)];
            break;
        }
    }
    return numStr;
}

+ (NSString *)extractMsgIdByControlData:(id)aControlData withKey:(NSString *)aKey{
    SEL msgWrapSel = NSSelectorFromString(@"m_oSelectedMessageWrap");
    if([aControlData respondsToSelector:msgWrapSel]){
        id msgWrap = [aControlData performSelector:msgWrapSel];
        [NKWCUtil log:@"[KWLM8]-%@",msgWrap];
        return [self extractMsgIdByWrap:msgWrap withKey:aKey];
    }
    return nil;
}

#pragma mark - UIAlertViewDelegate
+ (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(buttonIndex == [alertView cancelButtonIndex]+1){
        [self setAutoOpenRedEnvelopEnabled:![self autoOpenRedEnvelopEnabled]];
    }
}
@end