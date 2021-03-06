//
//  FDWeiBoItemViewModel.m
//  新浪个人中心
//
//  Created by 首牛科技 on 2018/12/17.
//  Copyright © 2018 黄智浩. All rights reserved.
//

#define KScreenWidth  [UIScreen mainScreen].bounds.size.width
#import "FDWeiBoItemViewModel.h"
#import "OCTEmoji.h"

@interface FDWeiBoItemViewModel()
@property(nonatomic,readwrite)CGFloat cellHeight;
@property(strong,nonatomic,readwrite)FDPhotoViewModel *photoViewModel;
@property(strong,nonatomic,readwrite)FDRetweetPhotoViewModel *retweetPhotoViewModel;
@end
@implementation FDWeiBoItemViewModel
- (instancetype)initWithWeiBo:(FDWeiboModel *)weibo{
    if (self = [super init]) {
        [self layoutWithWeiBo:weibo];
        BOOL isRetweetPhotoViewModelExit = (weibo.mblog.retweeted_status.pic_ids.count > 0);
        if (isRetweetPhotoViewModelExit) {
            self.photoViewModel = nil;
            self.retweetPhotoViewModel = [[FDRetweetPhotoViewModel alloc]initWithStatus:weibo.mblog.retweeted_status];
        }else{
            self.retweetPhotoViewModel = nil;
            self.photoViewModel = [[FDPhotoViewModel alloc]initWithStatus:weibo.mblog];
        }
    }
    return self;
}
- (void)layoutWithWeiBo:(FDWeiboModel *)weibo{
    
    _weibo = weibo;
    [self configureNameLayoutAttribuatesWithWeibo:weibo];
    [self configureSourceLayoutAttribuatesWithWeibo:weibo];
    _textLayout = [self configureTextLayoutAttribuatesWithWeibo:weibo.mblog isRetweet:NO];
    _textPartHeight = kStatusCellTopMargin + _textLayout.textBoundingSize.height;
    if (weibo.mblog.retweeted_status) {
        _retweetTextLayout = [self configureTextLayoutAttribuatesWithWeibo:weibo.mblog.retweeted_status isRetweet:YES];
        _retweetTextPartHeight = kStatusCellTopMargin + _retweetTextLayout.textBoundingSize.height;
    }
    [self configureBottomBarToolWithStatus:weibo.mblog];
}
- (YYTextLayout *)configureTextLayoutAttribuatesWithWeibo:(FDWeiboContentModel *)weibo isRetweet:(BOOL)isRetweet{
    
    if (!weibo.text.length) {return nil;}
    NSMutableAttributedString *textAttribuatedString = [[NSMutableAttributedString alloc]initWithString:weibo.text];
    textAttribuatedString.yy_font = AAFont(isRetweet?kStatusNameFontSize:kStatusTextFontSize);
    textAttribuatedString.yy_color = [UIColor blackColor];
    textAttribuatedString.yy_lineSpacing = 5.f;
    [self mathRegexWithStatusText:textAttribuatedString];
    [self mathEmojiRegexWithStatusText:textAttribuatedString];
    YYTextContainer *textContainer = [YYTextContainer containerWithSize:CGSizeMake(AAdaption(kStatusTextWidth), CGFLOAT_MAX)];
    return [YYTextLayout layoutWithContainer:textContainer text:textAttribuatedString];
}
- (void)configureNameLayoutAttribuatesWithWeibo:(FDWeiboModel *)weibo{
    
    NSMutableAttributedString *nameAttribuatedString = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@"%@ ",weibo.mblog.user.screen_name]];
    if ([weibo.mblog.user.mbrank unsignedIntegerValue] > 0) {
        UIImage *vipLevelImage = [UIImage imageNamed:[NSString stringWithFormat:@"common_icon_membership_level%zd",[weibo.mblog.user.mbrank unsignedIntegerValue]]];
        NSMutableAttributedString *attachVipAttribuatedString = [NSMutableAttributedString yy_attachmentStringWithContent:vipLevelImage contentMode:UIViewContentModeCenter attachmentSize:vipLevelImage.size alignToFont:AAFont(kStatusNameFontSize) alignment:YYTextVerticalAlignmentCenter];
        [nameAttribuatedString insertAttributedString:attachVipAttribuatedString atIndex:nameAttribuatedString.string.length];
    }
    
    nameAttribuatedString.yy_font = AAFont(kStatusNameFontSize);
    nameAttribuatedString.yy_color = [weibo.mblog.user.mbrank unsignedIntegerValue] > 0?kStatusVipNameColor:kStatusNormalColor;
    YYTextContainer *nameContainer = [YYTextContainer containerWithSize:CGSizeMake(AAdaption(kStatusNameWidth), CGFLOAT_MAX)];
    _nameLayout = [YYTextLayout layoutWithContainer:nameContainer text:nameAttribuatedString];
    _avatarPartHeight = 50 + kStatusCellTopMargin;
}
- (void)configureSourceLayoutAttribuatesWithWeibo:(FDWeiboModel *)weibo{
    
    if (weibo.mblog.created_at.length) {
        NSMutableAttributedString *timeAttribuatedString = [[NSMutableAttributedString alloc]initWithString:weibo.mblog.created_at];
        timeAttribuatedString.yy_font = AAFont(kStatusSourceFontSize);
        timeAttribuatedString.yy_color = kStatusSourceTimeColor;
        YYTextContainer *sourceTimeContainer = [YYTextContainer containerWithSize:CGSizeMake(kStatusNameWidth, CGFLOAT_MAX)];
        _sourceTimeLayout = [YYTextLayout layoutWithContainer:sourceTimeContainer text:timeAttribuatedString];
    }else{
        _sourceTimeLayout = nil;
    }
}
- (void)mathRegexWithStatusText:(NSMutableAttributedString *)statusText{
    
    NSString *patternAt = kRegexOfAt;
    NSString *patternTopic = kRegexOfTopic;
    NSString *patternURL = kRegexOfURL;
    NSString *patternPhone = kRegexOfPhone;
    NSString *patternEmail = kRegexOfEmail;
    NSString *pattern = [NSString stringWithFormat:@"%@|%@|%@|%@|%@",patternAt,patternTopic,patternURL,patternPhone,patternEmail];
    [statusText.string enumerateStringsMatchedByRegex:pattern usingBlock:^(NSInteger captureCount, NSString *const __unsafe_unretained *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        
        NSString *capturedString = *capturedStrings;
        NSRange range = *capturedRanges;
        if (capturedString.length <= 1 && range.location == NSNotFound) {return;}
        if ([statusText yy_attribute:YYTextHighlightAttributeName atIndex:range.location] == nil) {
            [statusText yy_setTextHighlightRange:range color:kStatusSourceLinkColor backgroundColor:[UIColor colorWithWhite:0.000 alpha:0.220] tapAction:^(UIView * _Nonnull containerView, NSAttributedString * _Nonnull text, NSRange range, CGRect rect) {
                
            }];
        }
    }];
}
- (void)mathEmojiRegexWithStatusText:(NSMutableAttributedString *)statusText{
    
    NSMutableAttributedString *statusTextTemp = statusText.mutableCopy;
    NSString *patternEmoji = kRegexOfEmoji;
    __block NSUInteger cycleCount = 0;
    __block NSUInteger locationSum = 0;
    [statusText.string enumerateStringsMatchedByRegex:patternEmoji usingBlock:^(NSInteger captureCount, NSString *const __unsafe_unretained *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        NSString *capturedString = *capturedStrings;
        NSRange range = *capturedRanges;
        if (capturedString.length <= 1 && range.location == NSNotFound) {return;}
        if ([statusText yy_attribute:YYTextHighlightAttributeName atIndex:range.location] == nil){
            NSString *emojiString = [statusTextTemp.string substringWithRange:range];
            NSString *emojiImageName = @"emojiDefault";
            OCTEmoji *emoji = [[OCTEmojiManager sharedInstance]emojiWithEmojiName:emojiString];
            if (emoji) { emojiImageName = emoji.png;}
            UIImage *replaceImage = [UIImage imageWithName:emojiImageName size:CGSizeMake(20, 20)];
            NSMutableAttributedString *emojiAttribuatedString = [NSMutableAttributedString yy_attachmentStringWithEmojiImage:replaceImage fontSize:AAdaption(kStatusTextFontSize)];
            NSRange tempRange = NSMakeRange(range.location - (locationSum - cycleCount), range.length);
            [statusText replaceCharactersInRange:tempRange withAttributedString:emojiAttribuatedString];
            locationSum += range.length;
            cycleCount ++;
        }
    }];
}
- (void)configureBottomBarToolWithStatus:(FDWeiboContentModel *)status{
    
    _repostLayout = [self configureBottomBatToolPartWithCount:status.reposts_count attachImageName:@"artical_detail_icon_repost"];
    _commentLayout = [self configureBottomBatToolPartWithCount:status.comments_count attachImageName:@"commentlist_icon_comment"];
    _attitudesLayout = [self configureBottomBatToolPartWithCount:status.attitudes_count attachImageName:@"commentlist_icon_unlike"];
}
- (YYTextLayout *)configureBottomBatToolPartWithCount:(NSNumber *)count attachImageName:(NSString *)imageName{
    
    NSMutableAttributedString *countSring = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:@" %@",count]];
    countSring.yy_font = AAFont(13);
    countSring.yy_color = kStatusSourceTimeColor;
    UIImage *attachImage = [UIImage imageNamed:imageName];
    NSMutableAttributedString *attachAttribuatedString = [NSMutableAttributedString yy_attachmentStringWithContent:attachImage contentMode:UIViewContentModeCenter attachmentSize:attachImage.size alignToFont:AAFont(13) alignment:YYTextVerticalAlignmentCenter];
    [attachAttribuatedString insertAttributedString:countSring atIndex:attachAttribuatedString.string.length];
    YYTextContainer *container = [YYTextContainer containerWithSize:CGSizeMake(AAdaption(0.33 * WIDTH), CGFLOAT_MAX)];
    return [YYTextLayout layoutWithContainer:container text:attachAttribuatedString];
}

- (CGFloat)cellHeight{
     return self.avatarPartHeight + self.textPartHeight + kStatusCellTopMargin + (self.photoViewModel.photoHeight + self.retweetPhotoViewModel.photoHeight + kStatusCellTopMargin) + self.retweetTextPartHeight + kStatusBottomBarHeight;
}
@end
