//
//  BRMutableDatePickerView.m
//  BRPickerViewDemo
//
//  Created by 任波 on 2019/12/5.
//  Copyright © 2019 91renb. All rights reserved.
//

#import "BRMutableDatePickerView.h"
#import "NSDate+BRPickerView.h"
#import "BRPickerViewMacro.h"

/// 标题栏高度（包括确定/取消，和年/月/日）
#define kTitleBarViewHeight 88
/// 滚轮选择器的高度
#define kPickerViewHeight 216
/// 主题颜色
#define kThemeColor [UIColor blueColor]

@interface BRMutableDatePickerView ()<UIPickerViewDataSource, UIPickerViewDelegate>
// 遮罩背景视图
@property (nonatomic, strong) UIView *maskView;
// 弹出背景视图
@property (nonatomic, strong) UIView *alertView;
// 标题栏背景视图
@property (nonatomic, strong) UIView *titleBarView;
// 左边取消按钮
@property (nonatomic, strong) UIButton *cancelBtn;
// 右边确定按钮
@property (nonatomic, strong) UIButton *doneBtn;
// 中间标题
@property (nonatomic, strong) UILabel *titleLabel;

/** 时间选择器 */
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIButton *monthBtn;
@property (nonatomic, strong) UIButton *dayBtn;

/// 日期存储数组
@property(nonatomic, copy) NSArray *yearArr;
@property(nonatomic, copy) NSArray *monthArr;
@property(nonatomic, copy) NSArray *dayArr;

/// 记录 年、月、日、时、分、秒 当前选择的位置
@property(nonatomic, assign) NSInteger yearIndex;
@property(nonatomic, assign) NSInteger monthIndex;
@property(nonatomic, assign) NSInteger dayIndex;

@end

@implementation BRMutableDatePickerView

#pragma mark - 初始化时间选择器
- (instancetype)init {
    if (self = [super init]) {
        self.isAutoSelect = NO;
        self.hiddenMonth = NO;
        self.hiddenDay = NO;
    }
    return self;
}

- (void)initUI {
    self.frame = SCREEN_BOUNDS;
    // 设置子视图的宽度随着父视图变化
    self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [self addSubview:self.maskView];
    
    [self addSubview:self.alertView];
    [self.alertView addSubview:self.titleBarView];
    //[self.titleBarView addSubview:self.titleLabel];
    [self.titleBarView addSubview:self.cancelBtn];
    [self.titleBarView addSubview:self.doneBtn];
}

#pragma mark - 背景遮罩视图
- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc]initWithFrame:SCREEN_BOUNDS];
        _maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
        // 设置子视图的大小随着父视图变化
        _maskView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _maskView.userInteractionEnabled = YES;
        UITapGestureRecognizer *myTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTapMaskView:)];
        [_maskView addGestureRecognizer:myTap];
    }
    return _maskView;
}

#pragma mark - 弹框视图
- (UIView *)alertView {
    if (!_alertView) {
        _alertView = [[UIView alloc]initWithFrame:CGRectMake(0, SCREEN_HEIGHT - kTitleBarViewHeight - kPickerViewHeight - BR_BOTTOM_MARGIN, SCREEN_WIDTH, kTitleBarViewHeight + kPickerViewHeight + BR_BOTTOM_MARGIN)];
        _alertView.backgroundColor = [UIColor whiteColor];
        _alertView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    }
    return _alertView;
}

#pragma mark - 标题栏视图
- (UIView *)titleBarView {
    if (!_titleBarView) {
        _titleBarView =[[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, kTitleBarViewHeight)];
        _titleBarView.backgroundColor = [UIColor whiteColor];
        _titleBarView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        // 设置标题栏底部分割线
        UIView *titleLineView = [[UIView alloc]initWithFrame:CGRectMake(0, 44 - 0.5f, _titleBarView.frame.size.width, 0.5f)];
        titleLineView.backgroundColor = BR_RGB_HEX(0xdadada, 1.0f);
        titleLineView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_titleBarView addSubview:titleLineView];
        
        // 年
        UILabel *yearLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 44, self.alertView.frame.size.width / 3, 44)];
        yearLabel.backgroundColor = [UIColor whiteColor];
        yearLabel.textColor = [UIColor darkGrayColor];
        yearLabel.font = [UIFont systemFontOfSize:16.0f];
        yearLabel.textAlignment = NSTextAlignmentCenter;
        yearLabel.text = @"年";
        [_titleBarView addSubview:yearLabel];
        
        // 月
        UILabel *monthLabel = [[UILabel alloc]initWithFrame:CGRectMake(1 * self.alertView.frame.size.width / 3, yearLabel.frame.origin.y, yearLabel.frame.size.width, yearLabel.frame.size.height)];
        monthLabel.backgroundColor = [UIColor whiteColor];
        monthLabel.textColor = [UIColor darkGrayColor];
        monthLabel.font = [UIFont systemFontOfSize:16.0f];
        monthLabel.textAlignment = NSTextAlignmentCenter;
        monthLabel.text = @"月";
        [_titleBarView addSubview:monthLabel];
        
        // 月-[不限]
        UIButton *monthBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        monthBtn.frame = CGRectMake(monthLabel.center.x + 10, yearLabel.frame.origin.y, 50, yearLabel.frame.size.height);
        monthBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        monthBtn.backgroundColor = [UIColor clearColor];
        monthBtn.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [monthBtn setTitleColor:kThemeColor forState:UIControlStateNormal];
        [monthBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateSelected];
        [monthBtn setTitle:@"[不限]" forState:UIControlStateNormal];
        [monthBtn addTarget:self action:@selector(clickMonthBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_titleBarView addSubview:monthBtn];
        self.monthBtn = monthBtn;
        
        // 日
        UILabel *dayLabel = [[UILabel alloc]initWithFrame:CGRectMake(2 * self.alertView.frame.size.width / 3, yearLabel.frame.origin.y, yearLabel.frame.size.width, yearLabel.frame.size.height)];
        dayLabel.backgroundColor = [UIColor whiteColor];
        dayLabel.textColor = [UIColor darkGrayColor];
        dayLabel.font = [UIFont systemFontOfSize:16.0f];
        dayLabel.textAlignment = NSTextAlignmentCenter;
        dayLabel.text = @"日";
        [_titleBarView addSubview:dayLabel];
        
        // 日-[不限]
        UIButton *dayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        dayBtn.frame = CGRectMake(dayLabel.center.x + 10, yearLabel.frame.origin.y, 50, yearLabel.frame.size.height);
        dayBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        dayBtn.backgroundColor = [UIColor clearColor];
        dayBtn.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [dayBtn setTitleColor:kThemeColor forState:UIControlStateNormal];
        [dayBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateSelected];
        [dayBtn setTitle:@"[不限]" forState:UIControlStateNormal];
        [dayBtn addTarget:self action:@selector(clickDayBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_titleBarView addSubview:dayBtn];
        self.dayBtn = dayBtn;
    }
    return _titleBarView;
}

- (void)clickMonthBtn:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.hiddenMonth = sender.selected;
    if (self.hiddenMonth) {
        self.hiddenDay = YES;
        self.dayBtn.selected = YES;
    }
    [self reloadData];
}

- (void)clickDayBtn:(UIButton *)sender {
    if (!self.hiddenMonth) {
        sender.selected = !sender.selected;
        self.hiddenDay = sender.selected;
        [self reloadData];
    } else {
        NSLog(@"请先选择月");
    }
}

- (void)reloadData {
    [self handlerInitData];
    [self.pickerView reloadAllComponents];
}

#pragma mark - 取消按钮
- (UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelBtn.frame = CGRectMake(5, 8, 60, 28);
        _cancelBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        _cancelBtn.backgroundColor = [UIColor clearColor];
        _cancelBtn.titleLabel.font = [UIFont systemFontOfSize:16.0f];
        [_cancelBtn setTitleColor:kThemeColor forState:UIControlStateNormal];
        [_cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(clickCancelBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

#pragma mark - 确定按钮
- (UIButton *)doneBtn {
    if (!_doneBtn) {
        _doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _doneBtn.frame = CGRectMake(SCREEN_WIDTH - 60 - 5, 8, 60, 28);
        _doneBtn.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        _doneBtn.backgroundColor = [UIColor clearColor];
        _doneBtn.titleLabel.font = [UIFont systemFontOfSize:16.0f];
        [_doneBtn setTitleColor:kThemeColor forState:UIControlStateNormal];
        [_doneBtn setTitle:@"确定" forState:UIControlStateNormal];
        [_doneBtn addTarget:self action:@selector(clickDoneBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _doneBtn;
}

#pragma mark - 中间标题label
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(5 + 60 + 2, 0, SCREEN_WIDTH - 2 * (5 + 60 + 2), kTitleBarViewHeight)];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:16.0f];
        _titleLabel.textColor = [UIColor darkGrayColor];
        _titleLabel.text = self.title;
    }
    return _titleLabel;
}

#pragma mark - 时间选择器
- (UIPickerView *)pickerView {
    if (!_pickerView) {
        _pickerView = [[UIPickerView alloc]initWithFrame:CGRectMake(0, kTitleBarViewHeight, SCREEN_WIDTH, kPickerViewHeight)];
        _pickerView.backgroundColor = [UIColor whiteColor];
        _pickerView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        _pickerView.showsSelectionIndicator = YES;
    }
    return _pickerView;
}

#pragma mark - 点击背景遮罩图层事件
- (void)didTapMaskView:(UITapGestureRecognizer *)sender {
    [self dismiss];
}

#pragma mark - 取消按钮的点击事件
- (void)clickCancelBtn {
    [self dismiss];
}

#pragma mark - 弹出选择器视图
- (void)show {
    [self initUI];
    [self handlerInitData];
    // 添加时间选择器
    [self.alertView addSubview:self.pickerView];
    [self.pickerView reloadAllComponents];
    // 默认滚动的行
    [self scrollToSelectDate:self.selectDate animated:NO];
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow addSubview:self];
    // 动画前初始位置
    CGRect rect = self.alertView.frame;
    rect.origin.y = SCREEN_HEIGHT;
    self.alertView.frame = rect;
    // 弹出动画
    self.maskView.alpha = 1;
    [UIView animateWithDuration:0.3 animations:^{
        CGRect rect = self.alertView.frame;
        rect.origin.y -= kPickerViewHeight + kTitleBarViewHeight + BR_BOTTOM_MARGIN;
        self.alertView.frame = rect;
    }];
}

#pragma mark - 关闭选择器视图
- (void)dismiss {
    // 关闭动画
    [UIView animateWithDuration:0.2 animations:^{
        CGRect rect = self.alertView.frame;
        rect.origin.y += kPickerViewHeight + kTitleBarViewHeight + BR_BOTTOM_MARGIN;
        self.alertView.frame = rect;
        self.maskView.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}


#pragma mark - 确定按钮的点击事件
- (void)clickDoneBtn {
    // 点击确定按钮后，执行block回调
    [self dismiss];
    
    if (!self.isAutoSelect && self.resultBlock) {
        NSString *selectValue = [NSDate br_getDateString:self.selectDate format:@"yyyy-MM-dd"];
        self.resultBlock(self.selectDate, selectValue);
    }
}

- (void)handlerInitData {
    // 1.最小日期限制
    if (!self.minDate) {
        self.minDate = [NSDate distantPast];
    }
    // 2.最大日期限制
    if (!self.maxDate) {
        self.maxDate = [NSDate distantFuture];
    }
    BOOL minMoreThanMax = [self.minDate br_compare:self.maxDate format:@"yyyy-MM-dd"] == NSOrderedDescending;
    NSAssert(!minMoreThanMax, @"最小日期不能大于最大日期！");
    if (minMoreThanMax) {
        // 如果最小日期大于了最大日期，就忽略两个值
        self.minDate = [NSDate distantPast];
        self.maxDate = [NSDate distantFuture];
    }
    
    // 3.默认选中的日期
    BOOL selectLessThanMin = [self.selectDate br_compare:self.minDate format:@"yyyy-MM-dd"] == NSOrderedAscending;
    BOOL selectMoreThanMax = [self.selectDate br_compare:self.maxDate format:@"yyyy-MM-dd"] == NSOrderedDescending;
    if (selectLessThanMin) {
        BRErrorLog(@"默认选择的日期不能小于最小日期！");
        self.selectDate = self.minDate;
    }
    if (selectMoreThanMax) {
        BRErrorLog(@"默认选择的日期不能大于最大日期！");
        self.selectDate = self.maxDate;
    }
    
    self.yearArr = [self getYearArr];
    self.monthArr = !self.hiddenMonth ? [self getMonthArr:self.selectDate.br_year] : nil;
    self.dayArr = (!self.hiddenMonth && !self.hiddenDay) ? [self getDayArr:self.selectDate.br_year month:self.selectDate.br_month] : nil;
    
    // 根据 默认选择的日期 计算出 对应的索引
    self.yearIndex = self.selectDate.br_year - self.minDate.br_year;
    self.monthIndex = self.selectDate.br_month - ((self.yearIndex == 0) ? self.minDate.br_month : 1);
    self.dayIndex = self.selectDate.br_day - ((self.yearIndex == 0 && self.monthIndex == 0) ? self.minDate.br_day : 1);
}

#pragma mark - 更新日期数据源数组
- (void)reloadDateArrayWithUpdateMonth:(BOOL)updateMonth updateDay:(BOOL)updateDay {
    // 1.更新 monthArr
    if (self.yearArr.count == 0) {
        return;
    }
    NSString *yearString = self.yearArr[self.yearIndex];
    if (updateMonth) {
        self.monthArr = [self getMonthArr:[yearString integerValue]];
    }
    
    // 2.更新 dayArr
    if (self.monthArr.count == 0) {
        return;
    }
    NSString *monthString = self.monthArr[self.monthIndex];
    if (updateDay) {
        self.dayArr = [self getDayArr:[yearString integerValue] month:[monthString integerValue]];
    }
}

// 获取 yearArr 数组
- (NSArray *)getYearArr {
    NSMutableArray *tempArr = [NSMutableArray array];
    for (NSInteger i = self.minDate.br_year; i <= self.maxDate.br_year; i++) {
        [tempArr addObject:[@(i) stringValue]];
    }
    return [tempArr copy];
}

// 获取 monthArr 数组
- (NSArray *)getMonthArr:(NSInteger)year {
    NSInteger startMonth = 1;
    NSInteger endMonth = 12;
    if (year == self.minDate.br_year) {
        startMonth = self.minDate.br_month;
    }
    if (year == self.maxDate.br_year) {
        endMonth = self.maxDate.br_month;
    }
    NSMutableArray *tempArr = [NSMutableArray arrayWithCapacity:(endMonth - startMonth + 1)];
    for (NSInteger i = startMonth; i <= endMonth; i++) {
        [tempArr addObject:[@(i) stringValue]];
    }
    return [tempArr copy];
}

// 获取 dayArr 数组
- (NSArray *)getDayArr:(NSInteger)year month:(NSInteger)month {
    NSInteger startDay = 1;
    NSInteger endDay = [NSDate br_getDaysInYear:year month:month];
    if (year == self.minDate.br_year && month == self.minDate.br_month) {
        startDay = self.minDate.br_day;
    }
    if (year == self.maxDate.br_year && month == self.maxDate.br_month) {
        endDay = self.maxDate.br_day;
    }
    NSMutableArray *tempArr = [NSMutableArray array];
    for (NSInteger i = startDay; i <= endDay; i++) {
        [tempArr addObject:[NSString stringWithFormat:@"%@", @(i)]];
    }
    return [tempArr copy];
}

#pragma mark - 滚动到指定时间的位置
- (void)scrollToSelectDate:(NSDate *)selectDate animated:(BOOL)animated {
    // 根据 当前选择的日期 计算出 对应的索引
    NSInteger yearIndex = selectDate.br_year - self.minDate.br_year;
    NSInteger monthIndex = selectDate.br_month - ((yearIndex == 0) ? self.minDate.br_month : 1);
    NSInteger dayIndex = selectDate.br_day - ((yearIndex == 0 && monthIndex == 0) ? self.minDate.br_day : 1);
    NSArray *indexArr = @[@(yearIndex), @(monthIndex), @(dayIndex)];;
    
    for (NSInteger i = 0; i < indexArr.count; i++) {
        [self.pickerView selectRow:[indexArr[i] integerValue] inComponent:i animated:animated];
    }
}

#pragma mark - UIPickerViewDataSource
// 1. 设置 picker 的列数
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

// 2. 设置 picker 每列的行数
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSArray *rowsArr = @[@(self.yearArr.count), @(self.monthArr.count), @(self.dayArr.count)];;
    return [rowsArr[component] integerValue];
}

#pragma mark - UIPickerViewDelegate
// 3. 设置 picker 的 显示内容
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view {
    
    // 设置分割线的颜色
    for (UIView *subView in pickerView.subviews) {
        if (subView && [subView isKindOfClass:[UIView class]] && subView.frame.size.height <= 1) {
            subView.backgroundColor = [UIColor colorWithRed:195/255.0 green:195/255.0 blue:195/255.0 alpha:1.0];
        }
    }
    
    UILabel *label = (UILabel *)view;
    if (!label) {
        label = [[UILabel alloc]init];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:18.0f];
        label.textColor = [UIColor blackColor];
        // 字体自适应属性
        label.adjustsFontSizeToFitWidth = YES;
        // 自适应最小字体缩放比例
        label.minimumScaleFactor = 0.5f;
    }
    
    // 给选择器上的label赋值
    if (component == 0) {
        label.text = [self getYearText:row];
    } else if (component == 1) {
        label.text = [self getMonthText:row];
    } else if (component == 2) {
        label.text = [self getDayText:row];
    }
    
    return label;
}

// 4. 时间选择器 每次滚动后的回调方法
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (component == 0) {
        self.yearIndex = row;
        if (!self.hiddenMonth) {
            if (!self.hiddenDay) {
                [self reloadDateArrayWithUpdateMonth:YES updateDay:YES];
                [self.pickerView reloadComponent:1];
                [self.pickerView reloadComponent:2];
            } else {
                [self reloadDateArrayWithUpdateMonth:YES updateDay:NO];
                [self.pickerView reloadComponent:1];
            }
        }
    } else if (component == 1) {
        self.monthIndex = row;
        if (!self.hiddenDay) {
            [self reloadDateArrayWithUpdateMonth:NO updateDay:YES];
            [self.pickerView reloadComponent:2];
        }
    } else if (component == 2) {
        self.dayIndex = row;
    }
    
    NSString *format = @"yyyy-MM-dd";
    int year = [self.yearArr[self.yearIndex] intValue];
    if (!self.hiddenMonth) {
        int month = [self.monthArr[self.monthIndex] intValue];
        if (!self.hiddenDay) {
            int day = [self.dayArr[self.dayIndex] intValue];
            self.selectDate = [NSDate br_setYear:year month:month day:day];
            format = @"yyyy-MM-dd";
        } else {
            self.selectDate = [NSDate br_setYear:year month:month];
            format = @"yyyy-MM";
        }
    } else {
        self.selectDate = [NSDate br_setYear:year];
        format = @"yyyy";
    }
    
    // 设置是否开启自动回调
    if (self.isAutoSelect) {
        // 滚动完成后，执行block回调
        if (self.resultBlock) {
            NSString *selectValue = [NSDate br_getDateString:self.selectDate format:format];
            self.resultBlock(self.selectDate, selectValue);
        }
    }
}

// 设置行高
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 35.0f;
}

- (NSString *)getYearText:(NSInteger)row {
    NSString *yearString = self.yearArr[row];
    NSString *yearUnit = !self.hiddenDateUnit ? @"年" : @"";
    return [NSString stringWithFormat:@"%@%@", yearString, yearUnit];
}

- (NSString *)getMonthText:(NSInteger)row {
    NSString *monthString = self.monthArr[row];
    NSString *monthUnit = !self.hiddenDateUnit ? @"月" : @"";
    return [NSString stringWithFormat:@"%@%@", monthString, monthUnit];
}

- (NSString *)getDayText:(NSInteger)row {
    NSString *dayString = self.dayArr[row];
    NSString *dayUnit = !self.hiddenDateUnit ? @"日" : @"";
    dayString = [NSString stringWithFormat:@"%@%@", dayString, dayUnit];
    return dayString;
}

#pragma mark - getter 方法
- (NSArray *)yearArr {
    if (!_yearArr) {
        _yearArr = [NSArray array];
    }
    return _yearArr;
}

- (NSArray *)monthArr {
    if (!_monthArr) {
        _monthArr = [NSArray array];
    }
    return _monthArr;
}

- (NSArray *)dayArr {
    if (!_dayArr) {
        _dayArr = [NSArray array];
    }
    return _dayArr;
}

- (NSInteger)yearIndex {
    if (_yearIndex < 0) {
        return 0;
    }
    return MIN(_yearIndex, self.yearArr.count - 1);
}

- (NSInteger)monthIndex {
    if (_monthIndex < 0) {
        return 0;
    }
    return MIN(_monthIndex, self.monthArr.count - 1);
}

- (NSInteger)dayIndex {
    if (_dayIndex < 0) {
        return 0;
    }
    return MIN(_dayIndex, self.dayArr.count - 1);
}

- (NSDate *)selectDate {
    if (!_selectDate) {
        _selectDate = [NSDate date];
    }
    return _selectDate;
}

@end
