//
//  FloatViewSubView.m
//  Demo
//
//  Created by Cookie on 16/5/30.
//  Copyright © 2016年 Cookie. All rights reserved.
//

#import "FloatViewSubView.h"
#import "zhengqaun-Swift.h"

@implementation FloatViewSubView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.layer.cornerRadius = (self.bounds.size.width) / 2;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)initWithTitle:(NSString *)title url:(NSString*)url titleColor:(UIColor *)titleColor tag:(NSInteger)tag
{
    self.tag = tag;
    if (title) {
        [self initLabelWithTitle:title  url:url titleColor:(UIColor *)titleColor];
    }
    [self addTapGesture];
}

- (instancetype)initWithFrame:(CGRect)frame  url:(NSString*)url color:(UIColor *)color title:(NSString *)title titleColor:(UIColor *)titleColor tag:(NSInteger)tag
{
    if (self = [self initWithFrame:frame]) {
        self.backgroundColor = color ? color : [UIColor colorWithRed:30/255.0 green:110/255.0 blue:190/255.0 alpha:0.5];
        [self initWithTitle:title url:url  titleColor:(UIColor *)titleColor tag:tag];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame  url:(NSString*)url image:(UIImage *)image title:(NSString *)title titleColor:(UIColor *)titleColor tag:(NSInteger)tag
{
    if (self = [self initWithFrame:frame]) {
        if (image) {
            self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
            self.imageView.contentMode = UIViewContentModeScaleToFill;
            self.imageView.image = image;
            [self addSubview:self.imageView];
            [self initWithTitle:title  url:url titleColor:(UIColor *)titleColor tag:tag];
        }
    }
    return self;
}

+ (instancetype)floatViewSubViewWithFrame:(CGRect)frame  url:(NSString*)url color:(UIColor *)color title:(NSString *)title titleColor:(UIColor *)titleColor tag:(NSInteger)tag
{
    return [[self alloc]initWithFrame:frame url:url color:color title:title titleColor:(UIColor *)titleColor tag:(NSInteger)tag];
}

+ (instancetype)floatViewSubViewWithFrame:(CGRect)frame  url:(NSString*)url image:(UIImage *)image title:(NSString *)title titleColor:(UIColor *)titleColor tag:(NSInteger)tag
{
    return [[self alloc]initWithFrame:frame url:url image:image title:title titleColor:(UIColor *)titleColor tag:tag];
}

- (void)addTapGesture
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tap];
}

- (void)singleTap:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(floatViewSubViewClickedWithTag:)]) {
        [self.delegate floatViewSubViewClickedWithTag:self.tag];
    }
}


- (void)initLabelWithTitle:(NSString *)title url:(NSString*)url titleColor:(UIColor *)titleColor
{
    // 清除旧子视图（如果有）
    UIView *oldBlue = [self viewWithTag:9991];
    UIView *oldRed = [self viewWithTag:9992];
    [oldBlue removeFromSuperview];
    [oldRed removeFromSuperview];

    // 初始化 label
    if (!self.label) {
        self.label = [[UILabel alloc] init];
        [self addSubview:self.label];
        self.label.translatesAutoresizingMaskIntoConstraints = NO;

        NSLayoutConstraint * h_c = [NSLayoutConstraint constraintWithItem:self.label
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0
                                                                 constant:0];
        NSLayoutConstraint * v_c = [NSLayoutConstraint constraintWithItem:self.label
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1.0
                                                                 constant:0];
        NSLayoutConstraint * h_l = [NSLayoutConstraint constraintWithItem:self.label
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeLeft
                                                               multiplier:1.0
                                                                 constant:(self.bounds.size.width/6.0)];
        NSLayoutConstraint * h_r = [NSLayoutConstraint constraintWithItem:self.label
                                                                attribute:NSLayoutAttributeRight
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeRight
                                                               multiplier:1.0
                                                                 constant:(self.bounds.size.width/6.0)];
        NSLayoutConstraint * v_t = [NSLayoutConstraint constraintWithItem:self.label
                                                                attribute:NSLayoutAttributeTop
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0
                                                                 constant:(self.bounds.size.height/6.0)];
        NSLayoutConstraint * v_b = [NSLayoutConstraint constraintWithItem:self.label
                                                                attribute:NSLayoutAttributeBottom
                                                                relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0
                                                                 constant:(self.bounds.size.height/6.0)];
        [self addConstraints:@[h_c , v_c , h_l , h_r , v_t , v_b]];
    }

    // 文本样式
    self.label.numberOfLines = 0;
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.font = [UIFont systemFontOfSize:12];
    self.label.textColor = titleColor ?: [UIColor blackColor];
    self.label.text = title ?: @"";

    // 线条参数：紧贴文字（0pt），每条高 1pt，双线间隔 2pt
    const CGFloat textToFirstLine = 0.0;
    const CGFloat lineHeight = 1.0;
    const CGFloat linesGap = 2.0;

    // 计算单条线颜色：如果 titleColor 明确为红色则用红色，否则用蓝色
    UIColor *singleColor = [UIColor blueColor];
    if (titleColor && CGColorEqualToColor(titleColor.CGColor, [UIColor redColor].CGColor)) {
        singleColor = [UIColor redColor];
    }

    // 计算文字宽度，作为线条宽度（单行测量）
    CGFloat textWidth = 0.0;
    NSString *measureText = self.label.text ?: @"";
    NSDictionary *attrs = @{ NSFontAttributeName: self.label.font };
    CGRect textRect = [measureText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:attrs
                                                context:nil];
    textWidth = ceil(textRect.size.width);

    // 若宽度为 0（防御），则退回 label 的宽度约束方式
    BOOL useLabelWidth = (textWidth <= 0.0);

    // 辅助添加线条（线宽使用文字宽度并居中）
    void (^addLine)(UIColor *, NSInteger, CGFloat) = ^(UIColor *color, NSInteger tag, CGFloat topOffset) {
        UIView *line = [[UIView alloc] init];
        line.translatesAutoresizingMaskIntoConstraints = NO;
        line.backgroundColor = color;
        line.tag = tag;
        [self addSubview:line];

        // 垂直位置：紧贴 label.bottom（topOffset）
        NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:line
                                                               attribute:NSLayoutAttributeTop
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.label
                                                               attribute:NSLayoutAttributeBottom
                                                              multiplier:1.0
                                                                constant:topOffset];
        // 水平居中对齐 label
        NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:line
                                                                   attribute:NSLayoutAttributeCenterX
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.label
                                                                   attribute:NSLayoutAttributeCenterX
                                                                  multiplier:1.0
                                                                    constant:0];
        [self addConstraints:@[top, centerX]];

        if (useLabelWidth) {
            // 退回到与 label 等宽（当无法测量文字宽度时）
            NSLayoutConstraint *lead = [NSLayoutConstraint constraintWithItem:line
                                                                    attribute:NSLayoutAttributeLeading
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:self.label
                                                                    attribute:NSLayoutAttributeLeading
                                                                   multiplier:1.0
                                                                     constant:0];
            NSLayoutConstraint *trail = [NSLayoutConstraint constraintWithItem:line
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.label
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0
                                                                      constant:0];
            [self addConstraints:@[lead, trail]];
        } else {
            // 固定文字宽度
            NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:line
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:nil
                                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                                    multiplier:1.0
                                                                      constant:textWidth];
            [line addConstraint:width];
        }

        // 高度
        [line addConstraint:[NSLayoutConstraint constraintWithItem:line
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1.0
                                                          constant:lineHeight]];
        // 确保线条在最前面以避免被其他子视图遮挡
        [self bringSubviewToFront:line];
    };

    BOOL shouldShowTwoLines = NO;
    
    if (vpnDataModel.shared.isProxy) {
//        proxyIpDataArray
        
        for (NSString *urlString in vpnDataModel.shared.proxyIpDataArray) {
            if (urlString && url && [url rangeOfString:urlString options:NSCaseInsensitiveSearch].location != NSNotFound) {
                shouldShowTwoLines = YES;
                break;
            }
        }
        if (shouldShowTwoLines) {

        } else {
            addLine(UIColor.blueColor, 9991, textToFirstLine);
        }
    }else{
        // 非代理状态下，显示双线
        for (NSString *urlString in vpnDataModel.shared.proxyIpDataArray) {
            if (urlString && url && [url rangeOfString:urlString options:NSCaseInsensitiveSearch].location != NSNotFound) {
                shouldShowTwoLines = YES;
                break;
            }
        }
        if(shouldShowTwoLines == false) {
            addLine([UIColor blueColor], 9991, textToFirstLine);
            CGFloat secondTop = textToFirstLine + lineHeight + linesGap;
            addLine([UIColor redColor], 9992, secondTop);
        }else{
            addLine(UIColor.redColor, 9991, textToFirstLine);
        }
    }

    
    
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
