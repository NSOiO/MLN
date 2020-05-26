//
//  MLNUITabSegmentView.m
//  MLNUI
//
//  Created by MoMo on 2019/1/16.
//

#import "MLNUITabSegmentView.h"
#import "MLNUIKitHeader.h"
#import "MLNUIViewExporterMacro.h"
#import "MLNUIBadgeView.h"
#import "UIImage+MLNUIKit.h"
#import "UIView+MLNUILayout.h"
#import "MLNUILayoutNode.h"
#import "MLNUIViewPager.h"
#import "MLNUIViewConst.h"
#import "MLNUIBlock.h"

const CGFloat kMLNUITabSegmentViewDefaultHeight = 50.0f;
const CGFloat kMLNUITabSegmentViewLabelOffsetWeight = 10.0f;
#define kMLNUITabSegmentViewDefaultFontWeight UIFontWeightRegular
#define kMLNUITabDefaultColor [UIColor colorWithRed:50/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]

@interface MLNUITabSegmentView() <MLNUITabSegmentScrollHandlerDelegate>
{
    BOOL _shouldReConfigure;
    BOOL _startDragging;
}

@property (nonatomic, strong) NSArray<MLNUITabSegmentLabel *>  *segmentViews;
@property (nonatomic, strong) NSArray* segmentTitles;
@property (nonatomic, strong) UIScrollView  *contentScrollView;
@property (nonatomic, strong) UIImageView  *bottomPointView;

@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger toIndex;
@property (nonatomic, assign) NSInteger settingIndex;
@property (nonatomic, assign) CGFloat animationProgress;
@property (nonatomic, strong) CADisplayLink *animationLink;//动画定时器
@property (nonatomic, assign) CGFloat animationStartOffset;
@property (nonatomic, assign) CGFloat differenceLength;

@property (nonatomic, strong) MLNUITabSegmentViewConfiguration *configuration;
@property (nonatomic, strong) MLNUITabSegmentScrollHandler *scrollHandler;

@property (nonatomic, copy) MLNUITabSegmentViewTapActionBlock  tapBlock;
@property (nonatomic, copy) MLNUITabSegmentViewTapActionBlock luaui_tapBlock;

@property (nonatomic, strong) MLNUIBlock *luaui_tapCallback;
@property (nonatomic, strong) MLNUIBlock *luaui_clickCallback;
@property (nonatomic, strong) MLNUIBlock *luaui_scrollingCallback;
@property (nonatomic,weak) MLNUIViewPager *pageView;
@property (nonatomic, assign) CGFloat normalFontSize;
@property (nonatomic, assign) CGFloat selectScale;
@property (nonatomic, strong) UIColor *customTintColor;
@property (nonatomic, strong) UIColor *selectedTintColor;
@property (nonatomic, strong) UIColor *indicatorColor;
@property (nonatomic, assign) BOOL animated;

@property (nonatomic, assign) MLNUITabSegmentAlignment alignment;

@property (nonatomic, copy) void (^arrowTapBlock)(NSInteger index);

@property (nonatomic, strong) NSMutableDictionary *itemsOffsetCache;

@property (nonatomic, strong) NSMutableDictionary *itemBadgeInfo;

@property (nonatomic, assign) BOOL ignoreTapCallbackToLua;

@property (nonatomic, assign) NSUInteger missionIndex;
@property (nonatomic, assign) NSUInteger missionAnimated;

@end

@implementation MLNUITabSegmentView

- (instancetype)initWithMLNUILuaCore:(MLNUILuaCore *)luaCore
                          frame:(CGRect)frame
                  segmentTitles:(NSArray<NSString*> *)segmentTitles
                       tapBlock:(MLNUITabSegmentViewTapActionBlock)block{
    return [self initWithMLNUILuaCore:luaCore
                           frame:frame
                 segmentTitles:segmentTitles
                 configuration:[MLNUITabSegmentViewConfiguration defaultConfiguration]
                      tapBlock:block];
}

- (instancetype)initWithMLNUILuaCore:(MLNUILuaCore *)luaCore
                          frame:(CGRect)frame
                  segmentTitles:(NSArray<NSString*> *)segmentTitles
                  configuration:(MLNUITabSegmentViewConfiguration *)configuration
                       tapBlock:(MLNUITabSegmentViewTapActionBlock)block{
    if (self = [super initWithMLNUILuaCore:luaCore frame:frame]) {
        
        NSAssert(configuration != nil , @"MLNUITabSegmentView configuration can't nil，you can use [MLNUITabSegmentViewConfiguration defaultConfiguration]" );
        _settingIndex = -1;
        
        self.tapBlock = block;
        self.backgroundColor = [UIColor clearColor];
        
        self.scrollHandler = [[MLNUITabSegmentScrollHandler alloc] init];
        self.scrollHandler.delegate = self;
        
        self.configuration = configuration;
        
        [self setupContentScrollView];
        [self refreshSegmentTitles:segmentTitles];
    }
    return self;
}

- (instancetype)initWithMLNUILuaCore:(MLNUILuaCore *)luaCore frame:(CGRect)frame segmentTitles:(NSArray<NSString *> *)segmentTitles tintColor:(UIColor *)tintColor {
    
    if (self = [self initWithMLNUILuaCore:luaCore
                                frame:frame
                        segmentTitles:segmentTitles
                             tapBlock:self.luaui_tapBlock]) {
        self.segmentTitles = segmentTitles;
        __unsafe_unretained MLNUILayoutNode *node = self.luaui_node;
        [node changeX:frame.origin.x];
        [node changeY:frame.origin.y];
        MLNUICheckWidth(frame.size.width);
        MLNUICheckHeight(frame.size.height);
        [node changeWidth:frame.size.width];
        [node changeHeight:frame.size.height];
        tintColor = tintColor?:kMLNUITabDefaultColor;
        self.configuration.customTiniColor = tintColor;
        _customTintColor = tintColor;
        _shouldReConfigure = YES;
        _missionIndex = -1;
    }
    return self;
}

- (void)refreshSegmentTitles:(NSArray<NSString*> *)segmentTitles {
    self.toIndex = -1;
    [self removeAnimation];
    
    for (MLNUITabSegmentLabel *segmentLabel in self.segmentViews) {
        [segmentLabel removeFromSuperview];
    }
    [self.itemsOffsetCache  removeAllObjects];
    self.segmentViews = nil;
    self.currentIndex = 0;
    
    CGFloat left = self.configuration.leftPadding;
    
    NSMutableArray *marr = [NSMutableArray array];
    
   CGFloat  labelOffset = (self.configuration.selectScale - 1.0) * kMLNUITabSegmentViewLabelOffsetWeight;
    
    for (int i=0; i<segmentTitles.count; i++) {
        NSString *title = [segmentTitles objectAtIndex:i];
        if (![title isKindOfClass:[NSString class]]) {
            title = nil;
        }
        CGSize size = CGSizeZero;
        if (@available(iOS 8.2, *)) {
            size = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.configuration.normalFontSize weight:[MLNUITabSegmentViewConfiguration getFontWeightWithProgress:1.0]]} context:nil].size;
            
        } else {
            size = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.configuration.normalFontSize]} context:nil].size;
        }
        CGFloat width = ceil(size.width) + 2;
        CGFloat height = ceil(size.height);
        MLNUITabSegmentLabel *segmentLabel = [[MLNUITabSegmentLabel alloc] initWithFrame:CGRectMake(left, (self.frame.size.height-height)/2.0 + labelOffset, width, height) fontSize:self.configuration.normalFontSize];
        segmentLabel.titleLabel.text = title;
        [self setupTabLabeBadgeTitlel:segmentLabel withIndex:i];
        
        segmentLabel.titleLabel.textColor = self.configuration.customTiniColor ? self.configuration.customTiniColor : kMLNUITabDefaultColor;
        segmentLabel.tag = i;
        segmentLabel.exclusiveTouch = YES;
        
        if (i == self.currentIndex) {
            [segmentLabel setLabelScale:self.configuration.selectScale fontWeight:[MLNUITabSegmentViewConfiguration getFontWeightWithProgress:1.0]];
            if (_selectedTintColor) {
                segmentLabel.titleLabel.textColor = _selectedTintColor;
            }
            CGPoint center = self.bottomPointView.center;
            center.x = CGRectGetMidX(segmentLabel.frame);
            self.bottomPointView.center = center;
        }
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapSegmentLabel:)];
        [segmentLabel addGestureRecognizer:tap];
        
        [self.contentScrollView addSubview:segmentLabel];
        [marr addObject:segmentLabel];
        
        left = left + segmentLabel.frame.size.width + self.configuration.itemPadding;
    }
    self.segmentViews = marr;
    
    CGFloat width = left-self.configuration.itemPadding+self.configuration.rightPadding;
    if (segmentTitles.count == 0) {
        width = 0;
    }
    self.bottomPointView.backgroundColor = self.configuration.indicatorColor?:(self.configuration.selectedColor ?: self.configuration.customTiniColor);
    self.contentScrollView.contentSize = CGSizeMake(width, 1);
    
    [self layoutSegmentTitle];
    
    if (_currentIndex < self.segmentViews.count && _currentIndex >= 0) {
        MLNUITabSegmentLabel* label = _segmentViews[_currentIndex];
        CGPoint center = self.bottomPointView.center;
        center.x = label.frame.size.width / 2.0 + label.frame.origin.x;
        self.bottomPointView.center = center;
    }
}

- (void)dealloc4Lua
{
    [self.animationLink invalidate];
    self.animationLink = nil;
}

#pragma mark - getter
- (NSMutableDictionary *)itemsOffsetCache {
    if (!_itemsOffsetCache) {
        _itemsOffsetCache  = [NSMutableDictionary dictionary];
    }
    return _itemsOffsetCache;
}

- (NSMutableDictionary *)itemBadgeInfo
{
    if (!_itemBadgeInfo) {
        _itemBadgeInfo = [NSMutableDictionary dictionary];
    }
    return _itemBadgeInfo;
}

#pragma mark - public

- (void)setTapTitle:(NSString *)title atIndex:(NSInteger)index {
    if (index >= 0 && index < self.segmentViews.count) {
        [self.itemsOffsetCache removeObjectForKey:@(index)];
        MLNUITabSegmentLabel *label = [self.segmentViews objectAtIndex:index];
        [label setText:title];
        if (title) {
            NSMutableArray *originArray = [NSMutableArray arrayWithArray:_segmentTitles];
            [originArray replaceObjectAtIndex:index withObject:title];
            _segmentTitles = [originArray copy];
        }
        CGSize size = CGSizeZero;
        if (@available(iOS 8.2, *)) {
            size = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.configuration.normalFontSize weight:[MLNUITabSegmentViewConfiguration getFontWeightWithProgress:1.0]]} context:nil].size;
        } else {
            size = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.configuration.normalFontSize]} context:nil].size;
        }
        CGRect bounds = label.bounds;
        bounds.size = CGSizeMake( ceil(size.width)+2, ceil(size.height) );
        label.bounds = bounds;
        [label reLayoutLabel];
        
        [self resetAllSegmentViewWithCurrentIndex:self.currentIndex];
    }
}

- (void)setTapBadgeNum:(NSInteger)num atIndex:(NSInteger)index {
    if (index >= 0 && index < self.segmentViews.count  ) {
        MLNUITabSegmentLabel *label = [self.segmentViews objectAtIndex:index]?:nil;
        [label setBadgeNum:num];
    }
}

- (void)setTapBadgeTitle:(NSString *)title atIndex:(NSInteger)index {
    if (index >= 0 && index < self.segmentViews.count  ) {
        MLNUITabSegmentLabel *label = [self.segmentViews objectAtIndex:index]?:nil;
        [label setBadgeTitle:title];
    }
}

- (void)setRedDotHidden:(BOOL)hidden adIndex:(NSInteger)index {
    if (index >= 0 && index < self.segmentViews.count) {
        MLNUITabSegmentLabel *label = [self.segmentViews objectAtIndex:index]?:nil;
        if (!CGSizeEqualToSize(self.configuration.redDotSize, CGSizeZero) && !hidden) {
            [label resetRedDotSize:self.configuration.redDotSize];
        }
        [label setRedDotHidden:hidden];
    }
}

- (void)setTabSegmentHidden:(BOOL)hidden adIndex:(NSInteger)index {
    if (index >= 0 && index < self.segmentViews.count) {
        MLNUITabSegmentLabel *label = [self.segmentViews objectAtIndex:index]?:nil;
        if(label) {
            label.hidden = hidden;
        }
    }
}

- (void)setCurrentLabelIndex:(NSInteger)currentIndex animated:(BOOL)animated {
    if (self.currentIndex != currentIndex) {
        if (self.tapBlock) self.tapBlock(self, currentIndex);
        if (animated) {
            [self startAnimationWithIndex:currentIndex];
        }else {
            [self removeAnimation];
            [self animtionFromIndex:self.currentIndex toIndex:currentIndex progress:1];
            self.currentIndex = currentIndex;
            //滚动到当前tab使其显示
            self.contentScrollView.contentOffset = CGPointMake([self calculateOffsetWithIndex:self.currentIndex], 0);
        }
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.contentScrollView.contentOffset = CGPointMake([self calculateOffsetWithIndex:self.currentIndex], 0);
        }];
    }
}

- (void)setCurrentLabelIndexWithoutCallback:(NSInteger)currentIndex
{
    [self removeAnimation];
    [self animtionFromIndex:self.currentIndex toIndex:currentIndex progress:1];
    self.currentIndex = currentIndex;
    //滚动到当前tab使其显示
    self.contentScrollView.contentOffset = CGPointMake([self calculateOffsetWithIndex:self.currentIndex], 0);
}

- (CGFloat)calculateOffsetWithIndex:(NSInteger)index{
    if (index < 0 || index >= self.segmentViews.count || self.currentIndex < 0 || self.currentIndex >= self.segmentViews.count) {
        return 0.0f;
    }
    
    NSNumber *cacheOffset = [self.itemsOffsetCache objectForKey:@(index)];
    if (cacheOffset) {
        return [cacheOffset floatValue];
    }
    
    UIView *view = [self.segmentViews objectAtIndex:index];
    UIView *selectedView = [self.segmentViews objectAtIndex:self.currentIndex];
    CGFloat contentSizeWidth = self.contentScrollView.contentSize.width;
    CGFloat centerX = view.frame.origin.x + view.frame.size.width / 2.0;
    CGFloat viewWidth = view.frame.size.width;
    //计算切换后真实的centerX 已经contentSize.width
    if (index != self.currentIndex) {
        contentSizeWidth = self.contentScrollView.contentSize.width - (selectedView.frame.size.width / _configuration.selectScale * (_configuration.selectScale - 1)) + (view.frame.size.width * (_configuration.selectScale - 1));
        if (view.center.x > selectedView.center.x) {
            centerX = centerX + (view.frame.size.width * (_configuration.selectScale - 1)) / 2.0 - ( ceil(selectedView.frame.size.width / _configuration.selectScale) * (_configuration.selectScale - 1));
        } else if(view.center.x < selectedView.center.x) {
            centerX = centerX + (view.frame.size.width * _configuration.selectScale - view.frame.size.width) / 2.0;
        }
        viewWidth = view.frame.size.width * _configuration.selectScale;
    }
    CGFloat offsetX = 0.0f;
    if (centerX < self.frame.size.width / 2.0) {
    } else if (centerX > contentSizeWidth - self.frame.size.width / 2.0) {
        CGFloat contentWidth = contentSizeWidth > self.contentScrollView.frame.size.width ? contentSizeWidth : self.contentScrollView.frame.size.width;
        offsetX = contentWidth - self.frame.size.width;
    } else {
        offsetX = centerX - (self.frame.size.width)/2.0;
    }
    [self.itemsOffsetCache setObject:@(offsetX) forKey:@(index)];
    return offsetX;
}

- (void)setShowArrowActionWithBlock:(void(^)(NSInteger index))block atIndexs:(NSArray *)indexs {
    if (indexs && indexs.count) {
        _arrowTapBlock = block;
        for (NSNumber *num in indexs) {
            if ([num integerValue] < self.segmentViews.count) {
                MLNUITabSegmentLabel *label = [self.segmentViews objectAtIndex:[num integerValue]];
                [label setEnableShowArrow:YES];
            }
        }
    }
}

- (void)setCurrentIndex:(NSInteger)currentIndex
{
    _currentIndex = currentIndex;
    _settingIndex = -1;
}

#pragma mark - private
- (void)setupTabLabeBadgeTitlel:(MLNUITabSegmentLabel *)tabLabel withIndex:(NSInteger)index
{
    NSString *key = [NSString stringWithFormat:@"%ld",index];
    NSObject *obj = [self.itemBadgeInfo objectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        [tabLabel setBadgeTitle:(NSString *)obj];
    } else if([obj isKindOfClass:[NSNumber class]]) {
        [tabLabel setBadgeNum:[(NSNumber *)obj integerValue]];
    }
}

#pragma mark - event
- (void)didTapSegmentLabel:(UITapGestureRecognizer *)recognizer {
    MLNUITabSegmentLabel *tapLabel = (MLNUITabSegmentLabel *)recognizer.view;
    
    BOOL shouldReCalculate = NO;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(segmentView:correctIndexWithToIndex:)]) {
        NSInteger trueIndex = [self.delegate segmentView:self correctIndexWithToIndex:tapLabel.tag];
        shouldReCalculate = trueIndex != tapLabel.tag;
        if (trueIndex >= 0 && trueIndex < self.segmentViews.count) {
            tapLabel = [self.segmentViews objectAtIndex:trueIndex];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(segmentView:shouldScrollToIndex:)]) {
        if (![self.delegate segmentView:self shouldScrollToIndex:tapLabel.tag]) {
            return;
        }
    }
    
    
    if (_luaui_clickCallback) {
        [_luaui_clickCallback addIntegerArgument:tapLabel.tag + 1];
        [_luaui_clickCallback callIfCan];
    }
    
    //when recalculate or new tag != currentindex
    if (shouldReCalculate || tapLabel.tag != self.currentIndex) {
        [self setCurrentLabelIndex:tapLabel.tag animated:YES];
    }
}

#pragma mark - animation

- (void)removeAnimation {
    if (self.animationLink) {
        [self.animationLink invalidate];
        self.animationLink = nil;
        self.toIndex = -1;
    }
}

- (void)resetAllSegmentViewWithCurrentIndex:(NSInteger)currentIndex {
    MLNUITabSegmentLabel *currentLabel = nil;
    for (int i=0; i<self.segmentViews.count; i++) {
        MLNUITabSegmentLabel *segmentLabel = [self.segmentViews objectAtIndex:i];
        segmentLabel.titleLabel.textColor = self.configuration.customTiniColor ? self.configuration.customTiniColor : kMLNUITabDefaultColor;
        if (i == currentIndex) {
            currentLabel = segmentLabel;
            [segmentLabel setLabelScale:self.configuration.selectScale fontWeight:[MLNUITabSegmentViewConfiguration getFontWeightWithProgress:1.0]];
            if (_selectedTintColor) {
                segmentLabel.titleLabel.textColor = _selectedTintColor;
            }
        }else {
            [segmentLabel setLabelScale:1.0 fontWeight:[MLNUITabSegmentViewConfiguration getFontWeightWithProgress:0.0]];
            if (_selectedTintColor) {
                segmentLabel.titleLabel.textColor = _customTintColor;
            }
        }
    }
    [self layoutSegmentTitle];
    
    CGRect frame = self.bottomPointView.frame;
    frame.size.width = self.configuration.pointSize.width > 0 ? self.configuration.pointSize.width : 5.5;
    self.bottomPointView.frame = frame;
    CGPoint center = self.bottomPointView.center;
    center.x = CGRectGetMidX(currentLabel.frame);
    self.bottomPointView.center = center;
    self.bottomPointView.backgroundColor = self.configuration.indicatorColor?:(self.configuration.selectedColor?:self.configuration.customTiniColor);
}

- (void)startAnimationWithIndex:(NSInteger)toIndex {
    if (toIndex == self.toIndex) {
        return;
    }
    
    [self removeAnimation];
    [self resetAllSegmentViewWithCurrentIndex:self.currentIndex];
    
    self.toIndex = toIndex;
    self.animationProgress = 0;
    self.animationStartOffset = self.contentScrollView.contentOffset.x;
    self.differenceLength = [self calculateOffsetWithIndex:toIndex] - self.contentScrollView.contentOffset.x;
    
    self.animationLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(performAnimation)];
    [self.animationLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)performAnimation{
    if (self.animationProgress >= 1.0) {
        [self showAnimationCompleted];
        self.differenceLength = 0;
        self.animationStartOffset = 0;
    }else {
        self.animationProgress +=0.07;
        self.animationProgress = MAX(0.0, MIN(self.animationProgress, 1.0));
        [self animtionFromIndex:self.currentIndex toIndex:self.toIndex progress:self.animationProgress];
    }
}

- (void)animtionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    if (fromIndex >= self.segmentViews.count || toIndex >= self.segmentViews.count) {
        return;
    }
    if (_luaui_scrollingCallback) {
        CGFloat absoluteProgress =  (fromIndex == self.currentIndex) ? progress : (1.0 - progress);
        [_luaui_scrollingCallback addFloatArgument:absoluteProgress];
        [_luaui_scrollingCallback callIfCan];
    }
    MLNUITabSegmentLabel *oldLable = [self.segmentViews objectAtIndex:fromIndex];
    MLNUITabSegmentLabel *newLabel = [self.segmentViews objectAtIndex:toIndex];
    
    CGFloat fromScale = self.configuration.selectScale + (1-self.configuration.selectScale) * progress;
    CGFloat toScale = 1 + (self.configuration.selectScale-1) * progress;
    
    [oldLable setLabelScale:fromScale fontWeight:[MLNUITabSegmentViewConfiguration getFontWeightWithProgress:(1-progress)]];
    [newLabel setLabelScale:toScale fontWeight:[MLNUITabSegmentViewConfiguration getFontWeightWithProgress:progress]];
    
    oldLable.titleLabel.textColor = [self.configuration getColorWithProgress:(1 - progress)];
    newLabel.titleLabel.textColor = [self.configuration getColorWithProgress:progress];
    
    if (progress == 1) {
        CGFloat newFontSize = newLabel.titleLabel.font.pointSize;
        
        for (MLNUITabSegmentLabel* view in self.segmentViews) {
            if (view == newLabel) {
                continue;
            }
            CGFloat pointSize = view.titleLabel.font.pointSize;
            if (pointSize > oldLable.titleLabel.font.pointSize && pointSize <= newFontSize) {
                [view setLabelScale:fromScale fontWeight:[MLNUITabSegmentViewConfiguration getFontWeightWithProgress:(1-progress)]];
            }
        }
    }
    
    [self layoutSegmentTitle];
    
    
    CGFloat startPointX = CGRectGetMidX(oldLable.frame);
    CGFloat endPointX = CGRectGetMidX(newLabel.frame);
    
    CGFloat scale = fabs(1 - progress*2);
    CGFloat offset = 0;
    if (toIndex!=fromIndex) {
        offset = fabs((endPointX-startPointX))/(labs(toIndex-fromIndex)+2) ;
    }
    CGFloat baseWidth = self.configuration.pointSize.width > 0 ? self.configuration.pointSize.width : 5;
    CGFloat width = baseWidth + offset * (1 - scale);
    CGRect frame = self.bottomPointView.frame;
    frame.size.width = width;
    self.bottomPointView.frame = frame;
    
    CGPoint center = self.bottomPointView.center;
    center.x = startPointX + (endPointX-startPointX) * progress;
    self.bottomPointView.center = center;
    //calculate current offset
    CGFloat scrollOffset = self.animationStartOffset + self.differenceLength * progress;
    self.contentScrollView.contentOffset = CGPointMake(scrollOffset, 0);
}

- (void)layoutSegmentTitle {
    CGFloat left = self.configuration.leftPadding;
    CGFloat offSetY = 0;
    if (self.contentScrollView.contentSize.width < self.frame.size.width) {
        switch (_alignment) {
            case MLNUITabSegmentAlignmentCenter:
                offSetY = (self.frame.size.width - self.contentScrollView.contentSize.width)/2.0;
                break;
            case MLNUITabSegmentAlignmentRight:
                offSetY = self.frame.size.width - self.contentScrollView.contentSize.width;
                break;
            default:
                break;
        }
        
    }
    for (int i=0; i<self.segmentViews.count; i++) {
        MLNUITabSegmentLabel *afterLabel = [self.segmentViews objectAtIndex:i];
        CGRect frame = afterLabel.frame;
        frame.origin.x = left + offSetY;
        afterLabel.frame = frame;
        left += afterLabel.frame.size.width + self.configuration.itemPadding;
    }
    CGFloat width = left-self.configuration.itemPadding+self.configuration.rightPadding;
    if (width != self.contentScrollView.contentSize.width && _shouldReConfigure) {
        self.contentScrollView.contentSize = CGSizeMake(width, 1);
        [self layoutSegmentTitle];
        return;
    }
    self.contentScrollView.contentSize = CGSizeMake(width, 1);
}

- (void)showAnimationCompleted{
    self.currentIndex = self.toIndex;
    [self removeAnimation];
}


- (void)scrollWithOldIndex:(NSInteger)index toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    self.animationStartOffset = [self calculateOffsetWithIndex:index];
    self.differenceLength = [self calculateOffsetWithIndex:toIndex] - self.animationStartOffset;
    if (!_startDragging) {
        _startDragging = YES;
        self.contentScrollView.contentOffset =  CGPointMake(self.animationStartOffset , 0);
    }
    if ( toIndex < 0 || toIndex >= self.segmentViews.count) {
        return ;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(segmentView:shouldScrollToIndex:)]) {
        if (![self.delegate segmentView:self shouldScrollToIndex:toIndex]) {
            return;
        }
    }
    if (index == toIndex) { //此时说明滑动结束
        if (toIndex == self.currentIndex) {
            return;
        }
        [self setCurrentLabelIndex:toIndex animated:NO];
    }
    else {
        if (self.animationLink) {
            [self removeAnimation];
            [self resetAllSegmentViewWithCurrentIndex:index];
        }
        [self animtionFromIndex:index toIndex:toIndex progress:progress];
    }
}

- (void)scrollDidStart {
    _startDragging = NO;
    self.animationStartOffset = 0;
    self.differenceLength = 0;
}

#pragma mark - setup UI

- (void)setupContentScrollView {
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.showsHorizontalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self addSubview:scrollView];
    self.contentScrollView = scrollView;
    
    self.bottomPointView = [[UIImageView alloc] initWithFrame:CGRectZero];
    CGRect frame = self.bottomPointView.frame;
    frame.size.width = self.configuration.pointSize.width;
    frame.size.height = self.configuration.pointSize.height;
    frame.origin.y =  self.frame.size.height - self.configuration.pointInsetBottom;
    self.bottomPointView.frame = frame;
    self.bottomPointView.layer.cornerRadius = self.configuration.pointSize.height/2.0;
    self.bottomPointView.backgroundColor =  self.configuration.indicatorColor?:(self.configuration.selectedColor?:self.configuration.customTiniColor);
    self.bottomPointView.layer.masksToBounds = YES;
    [self.contentScrollView addSubview:self.bottomPointView];
}

#pragma mark - Layout For Lua
- (BOOL)luaui_layoutEnable
{
    return YES;
}


#pragma mark - Export For Lua
- (MLNUITabSegmentViewTapActionBlock)luaui_tapBlock {
    if (!_luaui_tapBlock) {
        __weak typeof(self) weakSelf = self;
        _luaui_tapBlock =  ^(MLNUITabSegmentView* view,NSInteger index) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.luaui_tapCallback && !strongSelf.ignoreTapCallbackToLua) {
                [strongSelf.luaui_tapCallback addIntArgument:(int)index + 1];
                [strongSelf.luaui_tapCallback callIfCan];
            }
            if (strongSelf.pageView) {
                [strongSelf.pageView scrollToPage:index aniamted:strongSelf.animated];
            }
            strongSelf.ignoreTapCallbackToLua = NO;
        };
    }
    return _luaui_tapBlock;
}

//bind viewPager
- (void)luaui_relatedToViewPager:(MLNUIViewPager*)viewPager animated:(NSNumber *)animatedValue
{
    BOOL animated = [animatedValue boolValue];
    MLNUICheckTypeAndNilValue(viewPager, @"ViewPager", [MLNUIViewPager class])
    self.pageView = viewPager;
    _animated = animated;
    viewPager.segmentViewHandler = (id<UIScrollViewDelegate>)self.scrollHandler;
    viewPager.tabSegmentView = self;
    self.delegate = viewPager;
    
    [viewPager setRecurrence:NO];
    if (viewPager.missionIndex == 0) {
        [viewPager scrollToPage:_currentIndex aniamted:animated];
    } else {
        [self luaui_setCurrentIndex:viewPager.missionIndex animated:@(viewPager.missionAnimated)];
    }
}

- (void)luaui_setNormalFontSize:(CGFloat)size {
    if (_normalFontSize == size) {
        return;
    }
    _normalFontSize = size;
    self.configuration.normalFontSize = size;
    _shouldReConfigure = YES;
    [self resetIfNeed];
}

- (void)luaui_setSelectScale:(CGFloat)scale {
    if (_selectScale == scale) {
        return;
    }
    _selectScale = scale;
    self.configuration.selectScale = scale;
    _shouldReConfigure = YES;
    [self resetIfNeed];
}

- (void)luaui_setCustomTintColor:(UIColor *)color
{
    MLNUICheckTypeAndNilValue(color, @"Color", [UIColor class])
    if (_customTintColor == color) {
        return;
    }
    _customTintColor = color;
    self.configuration.customTiniColor = color;
    [self colorSettingResetIfNeed];
}

- (void)luaui_setSelectedColor:(UIColor *)color
{
    MLNUICheckTypeAndNilValue(color, @"Color", [UIColor class])
    if (_selectedTintColor == color) {
        return;
    }
    _selectedTintColor = color;
    self.configuration.selectedColor = color;
    _shouldReConfigure = YES;
    [self colorSettingResetIfNeed];
}

- (void)luaui_setIndicatorColor:(UIColor *)color
{
    MLNUICheckTypeAndNilValue(color, @"Color", UIColor)
    if (_indicatorColor == color) {
        return;
    }
    _indicatorColor = color;
    self.configuration.indicatorColor = color;
    [self colorSettingResetIfNeed];
}

- (void)luaui_setTabSpacing:(NSInteger)tabSpacing
{
    if (self.configuration.itemPadding == tabSpacing) {
        return;
    }
    self.configuration.itemPadding = tabSpacing;
    _shouldReConfigure = YES;
    [self resetIfNeed];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self resetIfNeed];
}

- (void)colorSettingResetIfNeed {
    if (self.superview) {
        self.bottomPointView.backgroundColor = self.configuration.indicatorColor?:(self.configuration.selectedColor?:self.configuration.customTiniColor);
        for (int i=0; i<self.segmentViews.count; i++) {
            MLNUITabSegmentLabel *segmentLabel = [self.segmentViews objectAtIndex:i];
            if (i == self.currentIndex) {
                segmentLabel.titleLabel.textColor = self.configuration.selectedColor?:(self.configuration.customTiniColor?:kMLNUITabDefaultColor);
            }else {
                segmentLabel.titleLabel.textColor = self.configuration.customTiniColor?:kMLNUITabDefaultColor;
            }
        }
    }
}

- (void)resetIfNeed {
    if (self.superview && _shouldReConfigure) {
        NSInteger currentIndex = _currentIndex;
        [self refreshSegmentTitles:_segmentTitles];
        NSInteger targetIndex = _missionIndex != -1 ? _missionIndex : currentIndex;
        BOOL animated = _missionIndex != -1 ? _missionAnimated : NO;
        //由于选中当前页动作，会触发点击回调，需要在这种情况下忽略回调
        _ignoreTapCallbackToLua = YES;
        [self setCurrentLabelIndex:targetIndex animated:animated];
        _ignoreTapCallbackToLua = NO;
        _shouldReConfigure = NO;
    }
}

- (void)luaui_setCurrentIndex:(NSInteger)currentIndex animated:(NSNumber *)animatedValue
{
    BOOL animated = [animatedValue boolValue];
    if (currentIndex < 1 || currentIndex > self.segmentTitles.count) {
        return;
    }
    
    NSInteger trueIndex =  currentIndex - 1;
    if (self.superview == nil) {
        _missionIndex = trueIndex;
        _missionAnimated = animated;
        return;
    }
    [self setCurrentLabelIndex:trueIndex animated:animated];
    if (_pageView) {
        [_pageView scrollToPage:trueIndex aniamted:animated];
    }
    _settingIndex = currentIndex;
}

- (void)luaui_setTapTitle:(NSString*)title atIndex:(NSInteger)index {
    MLNUICheckTypeAndNilValue(title, @"string", [NSString class])
    if (index < 1 || index > self.segmentTitles.count) {
        return;
    }
    NSInteger trueIndex=  index - 1;
    [self setTapTitle:title atIndex:trueIndex];
}

- (void)luaui_setTapBadgeNum:(NSInteger)number atIndex:(NSInteger)index {
    if (index < 1 || index > self.segmentTitles.count) {
        return;
    }
    NSInteger trueIndex=  index - 1;
    [self.itemBadgeInfo setObject:@(number) forKey:[NSString stringWithFormat:@"%ld",trueIndex]];
    [self setTapBadgeNum:number atIndex:trueIndex];
}

- (void)luaui_setTapBadgeTitle:(NSString*)title atIndex:(NSInteger)index {
    NSInteger trueIndex=  index - 1;
    [self.itemBadgeInfo setObject:title?:@"" forKey:[NSString stringWithFormat:@"%ld",trueIndex]];
    MLNUICheckTypeAndNilValue(title, @"string", [NSString class])
    if (index < 1 || index > self.segmentTitles.count) {
        return;
    }
    [self setTapBadgeTitle:title atIndex:trueIndex];
}

- (void)luaui_setRedDotHidden:(BOOL)isHidden atIndex:(NSInteger)index {
    if (index < 1 || index > self.segmentTitles.count) {
        return;
    }
    NSInteger trueIndex=  index - 1;
    [self setRedDotHidden:isHidden adIndex:trueIndex];
}

- (void)luaui_changeRedDotStatusAtIndex:(NSInteger)index isShow:(BOOL)isShow {
    [self luaui_setRedDotHidden:!isShow atIndex:index];
}

- (void)luaui_animtionFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress {
    if ((fromIndex < 1 || fromIndex > self.segmentTitles.count) || (toIndex < 1 || toIndex > self.segmentTitles.count)) {
        return;
    }
    
    NSInteger trueFromeIndex = fromIndex - 1;
    NSInteger trueToIndex = toIndex - 1;
    
    [self animtionFromIndex:trueFromeIndex toIndex:trueToIndex progress:progress];
    
}

- (void)luaui_setCurrentIndex:(NSInteger)currentIndex {
    [self luaui_setCurrentIndex:currentIndex animated:@(YES)];
}

- (NSInteger)luaui_currentIndex {
    NSInteger realIndex = _currentIndex + 1;
    if (_settingIndex != -1) {
        realIndex = _settingIndex;
    }
    return realIndex;
}

- (void)luaui_setTapCallback:(MLNUIBlock *)block {
    MLNUICheckTypeAndNilValue(block, @"tapCallback", [MLNUIBlock class])
    self.luaui_tapCallback = block;
}

- (void)luaui_setAlignment:(MLNUITabSegmentAlignment)alignment {
    self.alignment = alignment;
    [self layoutSegmentTitle];
    if (_currentIndex < self.segmentViews.count && _currentIndex >= 0) {
        MLNUITabSegmentLabel* label = _segmentViews[_currentIndex];
        CGPoint center = self.bottomPointView.center;
        center.x = label.frame.size.width / 2.0 + label.frame.origin.x;
        self.bottomPointView.center = center;
    }
}

- (void)luaui_setTapClickedCallBack:(MLNUIBlock *)block {
    MLNUICheckTypeAndNilValue(block, @"Callback", [MLNUIBlock class])
    _luaui_clickCallback = block;
}

- (void)luaui_setTabScrollingListener:(MLNUIBlock *)block{
    MLNUICheckTypeAndNilValue(block, @"Callback", [MLNUIBlock class])
    _luaui_scrollingCallback = block;
}


#pragma mark - Export For Lua
LUAUI_EXPORT_VIEW_BEGIN(MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_PROPERTY(currentIndex, "luaui_setCurrentIndex:","luaui_currentIndex", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_PROPERTY(normalFontSize, "luaui_setNormalFontSize:","normalFontSize", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_PROPERTY(selectScale, "luaui_setSelectScale:","selectScale", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_PROPERTY(tintColor, "luaui_setCustomTintColor:","customTintColor", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_PROPERTY(selectedColor, "luaui_setSelectedColor:","selectedColor", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_PROPERTY(indicatorColor, "luaui_setIndicatorColor:","indicatorColor", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(relatedToViewPager, "luaui_relatedToViewPager:animated:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(setCurrentIndexAnimated, "luaui_setCurrentIndex:animated:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(setTapTitleAtIndex, "luaui_setTapTitle:atIndex:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(setTapBadgeNumAtIndex, "luaui_setTapBadgeNum:atIndex:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(setTapBadgeTitleAtIndex, "luaui_setTapBadgeTitle:atIndex:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(setRedDotHiddenAtIndex, "luaui_changeRedDotStatusAtIndex:isShow:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(changeRedDotStatusAtIndex, "luaui_changeRedDotStatusAtIndex:isShow:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(animtionFromIndexToIndexProgress, "luaui_animtionFromIndex:toIndex:progress:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(animationFromIndexToIndexProgress, "luaui_animtionFromIndex:toIndex:progress:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(addTabSelectedListener, "luaui_setTapCallback:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(setTabSelectedListener, "luaui_setTapCallback:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(setItemTabClickListener, "luaui_setTapClickedCallBack:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(setAlignment, "luaui_setAlignment:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(setTabSpacing, "luaui_setTabSpacing:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_METHOD(setTabScrollingListener, "luaui_setTabScrollingListener:", MLNUITabSegmentView)
LUAUI_EXPORT_VIEW_END(MLNUITabSegmentView,TabSegmentView, YES, "MLNUIView", "initWithMLNUILuaCore:frame:segmentTitles:tintColor:")



@end

@implementation MLNUITabSegmentViewConfiguration

+ (instancetype)defaultConfiguration {
    MLNUITabSegmentViewConfiguration *configuration = [[MLNUITabSegmentViewConfiguration alloc] init];
    
    configuration.leftPadding = 17;
    configuration.rightPadding = 17;
    configuration.itemPadding = 20;
    
    configuration.normalFontSize = 15;
    configuration.selectScale = 1.6;
    
    configuration.customTiniColor = [UIColor colorWithRed:50/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
    configuration.pointSize = CGSizeMake(5.5, 4);
    configuration.pointInsetBottom = 8;
    
    return configuration;
}


+ (UIFontWeight)getFontWeightWithProgress:(CGFloat)progress {
    progress = MIN(1.0, MAX(0.0, progress));
    CGFloat fontWeight = 0;
    if (@available(iOS 8.2, *)) {
        CGFloat weight = kMLNUITabSegmentViewDefaultFontWeight + (UIFontWeightHeavy - kMLNUITabSegmentViewDefaultFontWeight) * progress;
        
        fontWeight = kMLNUITabSegmentViewDefaultFontWeight;
        if (weight >= UIFontWeightRegular && weight < middleWeight(UIFontWeightRegular, UIFontWeightMedium)) {
            fontWeight = UIFontWeightRegular;
        }
        else if (weight >= middleWeight(UIFontWeightRegular, UIFontWeightMedium) &&
                 weight < middleWeight(UIFontWeightMedium, UIFontWeightSemibold)) {
            fontWeight = UIFontWeightMedium;
        }
        else if (weight >= middleWeight(UIFontWeightMedium, UIFontWeightSemibold) &&
                 weight < middleWeight(UIFontWeightSemibold, UIFontWeightBold)) {
            fontWeight = UIFontWeightSemibold;
        }
        else if (weight >= middleWeight(UIFontWeightSemibold, UIFontWeightBold) &&
                 weight < middleWeight(UIFontWeightBold, UIFontWeightHeavy)) {
            fontWeight = UIFontWeightBold;
        }
        else if (weight >= middleWeight(UIFontWeightBold, UIFontWeightHeavy)) {
            fontWeight = UIFontWeightHeavy;
        }
    } else {
        // Fallback on earlier versions
    }
    return fontWeight;
}

- (UIColor *)getColorWithProgress:(CGFloat)progress {
    if (!_selectedColor) {
        return _customTiniColor;
    }
    CGFloat red    = 0.0f;
    CGFloat green = 0.0f;
    CGFloat blue   = 0.0f;
    CGFloat alpha  = 0.0f;
    
    [_customTiniColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    CGFloat tred    = 0.0f;
    CGFloat tgreen = 0.0f;
    CGFloat tblue   = 0.0f;
    CGFloat talpha  = 0.0f;
    
    [_selectedColor getRed:&tred green:&tgreen blue:&tblue alpha:&talpha];
    
    CGFloat nred = red + (tred - red) * progress;
    CGFloat ngreen = green + (tgreen - green) * progress;
    CGFloat nblue = blue + (tblue - blue) * progress;
    CGFloat nalpha = alpha + (talpha - alpha) * progress;
    
    return [UIColor colorWithRed:nred green:ngreen blue:nblue alpha:nalpha];
}

static inline CGFloat middleWeight(CGFloat weightA, CGFloat weightB) {
    return (weightA + weightB) / 2.0;
}

@end

@interface MLNUITabSegmentLabel ()
@property (nonatomic, strong) UIImageView *redDotView;
@property (nonatomic, strong) MLNUIBadgeView *badgeView;
@property (nonatomic, assign) CGRect originRect;
@property (nonatomic, assign) CGFloat originFontSize;
@end

@implementation MLNUITabSegmentLabel

- (instancetype)initWithFrame:(CGRect)frame fontSize:(CGFloat)fontSize {
    self = [super initWithFrame:frame];
    if (self) {
        self.originRect = self.bounds;
        self.originFontSize = fontSize;
        
        CGRect frame = self.frame;
        self.layer.anchorPoint = CGPointMake(0, 1);
        self.frame = frame;
        
        [self addSubview:self.titleLabel];
        if (@available(iOS 8.2, *)) {
            self.titleLabel.font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular];
        } else {
            self.titleLabel.font = [UIFont systemFontOfSize:fontSize];
        }
    }
    return self;
}

- (void)reLayoutLabel {
    self.originRect = self.bounds;
    self.titleLabel.frame = self.bounds;
    [self layoutBadge];
}


- (void)setLabelScale:(CGFloat)scale fontWeight:(UIFontWeight)fontWeight {
    CGRect scaleRect = CGRectApplyAffineTransform(self.originRect, CGAffineTransformMakeScale(scale, scale));
    CGFloat scaleFontSize = self.originFontSize * scale;
    
    self.bounds = scaleRect;
    self.titleLabel.frame = self.bounds;
    if (@available(iOS 8.2, *)) {
        self.titleLabel.font = [UIFont systemFontOfSize:scaleFontSize weight:fontWeight];
    } else {
        self.titleLabel.font = [UIFont systemFontOfSize:scaleFontSize];
    }
    
    if ((_badgeView && !_badgeView.hidden) || (_redDotView && !_redDotView.hidden)) {
        [self layoutBadge];
    }
}


- (void)setText:(NSString *)text {
    [_titleLabel setText:text];
    if ((_badgeView && !_badgeView.hidden)) {
        [self layoutBadge];
    }
}

- (void)setBadgeNum:(NSInteger)num {
    if (num != 0) {
        [self createBadgeView];
        self.badgeView.hidden = NO;
        self.badgeView.badgeValue = [NSString stringWithFormat:@"%ld",num];
        [self layoutBadge];
    } else {
        [_badgeView setHidden:YES];
    }
}

- (void)setBadgeTitle:(NSString *)title {
    if (title.length > 0) {
        [self createBadgeView];
        self.badgeView.hidden = NO;
        self.badgeView.badgeValue =title;
        [self layoutBadge];
    } else {
        [_badgeView setHidden:YES];
    }
}

- (void)resetRedDotSize:(CGSize)size{
    if (_redDotView) {
        CGRect frame = _redDotView.frame;
        frame.size = size;
        _redDotView.frame = frame;
    }
}

- (void)setRedDotHidden:(BOOL)hidden {
    if (hidden) {
        _redDotView.hidden = YES;
    }else {
        [self createRedDotView];
        self.redDotView.hidden = NO;
        [self bringSubviewToFront:self.redDotView];
        [self layoutBadge];
    }
}

- (void)layoutBadge {
    if (_badgeView) {
        CGPoint center = CGPointMake(self.frame.size.width, 0);
        _badgeView.center = center;
    }
    
    if (_redDotView) {
        CGPoint redDotCenter = CGPointMake(self.frame.size.width+3, 0);
        _redDotView.center = redDotCenter;
    }
    
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(CGRectInset(self.bounds, 0, -20), point);
}

#pragma mark - lazy UI

- (MLNUIBadgeView *)createBadgeView {
    if (!_badgeView) {
        _badgeView = [[MLNUIBadgeView alloc] initWithOrigin:CGPointZero];
        _badgeView.hidden = YES;
        [self addSubview:_badgeView];
    }
    return _badgeView;
}

- (UIImageView *)createRedDotView {
    if (!_redDotView) {
        UIImage* image = [UIImage mlnui_imageWithColor:[UIColor colorWithRed:248/255.0 green:85/255.0 blue:67/255.0 alpha:1.0] finalSize:CGSizeMake(16, 16) cornerRadius:8];
        _redDotView = [[UIImageView alloc] initWithImage:image];
        CGRect frame = _redDotView.frame;
        frame.size = CGSizeMake(8, 8);
        _redDotView.frame = frame;
        _redDotView.backgroundColor = [UIColor clearColor];
        _redDotView.hidden = YES;
        [self addSubview:_redDotView];
    }
    return _redDotView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _titleLabel;
}

@end
