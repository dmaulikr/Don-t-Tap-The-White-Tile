//
//  ViewController.m
//  Don't Tap The White Tile
//
//  Created by wang yuchao on 2017/5/9.
//  Copyright © 2017年 wang yuchao. All rights reserved.
//

#import "ViewController.h"

#define kScreenW [UIScreen mainScreen].bounds.size.width
#define kScreenH [UIScreen mainScreen].bounds.size.height
#define kScreenB [UIScreen mainScreen].bounds
#define kLineCount 4  //每行色块的个数
#define kCellCount 200 //色块总个数,也就是50行
@interface ViewController ()

@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

///记录每一组的块的索引
@property (nonatomic, assign) int indexTag;
///存储每一行cell的可变数组
@property (nonatomic,strong) NSMutableArray *arrM;
///秒表计时器
@property (nonatomic, strong) NSTimer *timer;
///已用时间
@property (nonatomic, assign) CGFloat usedTime;
///记录已经点击的黑块个数
@property (nonatomic, assign) int blackCount;
///显示时间的Label
@property (nonatomic, strong) UILabel *timeLabel;
///显示主界面的View
@property (nonatomic, strong) UIView *mainView;
///即将消失
@property (nonatomic, assign) int displayNum;
///初始状态整体竖直偏移高度
@property (nonatomic, assign) CGFloat offsetTotal;
///每个cell高度
@property (nonatomic, assign) CGFloat itemHeight;

@end

@implementation ViewController
/*
 0.初始化布局,flowLayout
    设置色块的长和宽,因为屏幕的大小/4 不一定是整除的.所以只设置行列间距的话,间距是不均匀的,为了好看,适当的在色块的宽度-0.5;
 1.创建主界面,实现点击按钮进入游戏界面,主界面消失的方法.
 2.初始化主界面
    实现数据源方法,让每一行出现一个黑块
 3.实现玩游戏的逻辑
    3.1点击一行上滚一个格子的高度
    3.2点击白块变红出错,点黑块变灰滚到上一行.
    3.3漏掉一行的黑块报错
 4.添加秒表计时器,黑块计数器
 
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor blackColor];
    
    //0.初始化布局
    [self setFlowLayout];
    
    
    //1.初始化界面
    [self setMainView];
 
}

#pragma mark - 懒加载ArrM
-(NSMutableArray *)arrM {
    if (_arrM == nil) {
        
        _arrM = [NSMutableArray array];
    }
    return _arrM;
}

#pragma mark - 实现数据源方法

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return kCellCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    //创建cell
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    //设置cell
//    cell.tag = indexPath.item;
    //1.统一设置cell的颜色
    cell.backgroundColor =  [UIColor whiteColor];
    //2.每一行随意产生一个黑色的cell
    //思路:把同一行的4个cell存到数组里,0-3的随机数,设置黑块
    
    [self.arrM addObject:cell];
   
    //标志是3的时候从数组中随机取出一个cell让他变黑
    if (_indexTag == 3) {
        //产生随机的角标
        int randomNum = arc4random_uniform(4);
        UICollectionViewCell *blackCell = _arrM[randomNum];
        blackCell.backgroundColor = [UIColor blackColor];
        
    }
    _indexTag ++;
    //超过一行时,让标志重置为0,重新开始
    if (_indexTag > 3) {
        _indexTag = 0;
        //开始新的一行的时候清空数组,让他可以重新添加
        [_arrM removeAllObjects];
    }
    //返回cell
    return cell;
}

#pragma mark - 代理方法
//选中这一块调用此方法
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    //开始计时
    
    if (_timer == nil) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60 target:self selector:@selector(addTimeOfUserUse) userInfo:nil repeats:YES];
        //加入到运行循环
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    
    _displayNum = 1;
    //点击黑色时让他变灰,点白色让他变红
    if (cell.backgroundColor == [UIColor blackColor]) {
        
        cell.backgroundColor = [UIColor lightGrayColor];
        _blackCount ++;
    }else {
        //点白块,错误
        cell.backgroundColor = [UIColor redColor];
        //弹出提示框
        [self showError];
        //时间停止
        [_timer invalidate];
        return;
    }
    
    //点击黑块的时候让collectionView偏移
    if (self.collectionView.contentOffset.y == 0) {
        //到达终点
        return;
    }
    
    //这里的indexPath是点击当前一行的索引,应该让collectionView滚动到当前选中行的上一行的位置!!
    NSIndexPath *indexPathx = [NSIndexPath indexPathForItem:indexPath.item - kLineCount inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPathx atScrollPosition:UICollectionViewScrollPositionBottom animated:YES];
}

- (void)addTimeOfUserUse {
    _usedTime += 1.0 / 60;
}
#pragma mark - 将要消失的cell
//每个cell即将销毁的时候调用这个方法,如果漏掉了一行黑块直接判断错误.
//程序刚启动的时候也会调用此方法,当程序启动的时候就调用此方法中的 "弹框" 以及 "停止计时器",所以要用一个相当于启动器来启动监视黑色cell是否被干掉
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (cell.backgroundColor == [UIColor blackColor]) {
        if (_displayNum == 1) {
            [self showError];
            [_timer invalidate];
            self.displayNum = 0;
        }
    }
}


#pragma mark - 错误提示
- (void)showError {
    //Alert 警报
    UIAlertController *artController = [UIAlertController alertControllerWithTitle:@"最终结果" message:[NSString stringWithFormat:@"成绩是:%zd个",_blackCount]  preferredStyle:UIAlertControllerStyleAlert];
    //结束后返回主界面
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        //handler 处理器
        _timeLabel.text = [NSString stringWithFormat:@"累计用时%.2f秒",_usedTime];
        //重置数据
        _blackCount = 0;
        _displayNum = 0;
        [UIView animateWithDuration:0.2 animations:^{
            _mainView.alpha = 1;
        }];
    }];
    [artController addAction:action];
    [self presentViewController:artController animated:YES completion:nil];
    
}

#pragma mark - 初始化界面

- (void)setMainView {

    //主界面的大小
    UIView *mainView = [[UIView alloc]initWithFrame:kScreenB];
    _mainView = mainView;
    mainView.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:mainView];
    
    //@"开始游戏"按钮
    UIButton *button = [[UIButton alloc]init];
    [button setTitle:@"开始游戏" forState:UIControlStateNormal];
    button.bounds = CGRectMake(0, 0, 80, 30);
    button.backgroundColor = [UIColor blackColor];
    button.center = mainView.center;
    [mainView addSubview:button];
    [button addTarget:self action:@selector(hideMainView) forControlEvents:UIControlEventTouchUpInside];
    
    //显示时间
    UILabel *timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, kScreenW, 200)];
    _timeLabel = timeLabel;
    timeLabel.font = [UIFont systemFontOfSize:22];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    [mainView addSubview:timeLabel];
}

#pragma mark - 隐藏主界面进入游戏
- (void)hideMainView {
    
    _timer = nil;
    _usedTime = 0;
    
    CGFloat offset = (kCellCount / kLineCount - 1) * self.flowLayout.minimumLineSpacing  + (kCellCount / kLineCount ) * _itemHeight - kScreenH;
    _offsetTotal = offset;
    self.collectionView.contentOffset = CGPointMake(0, offset);
    
    //每次进入游戏把红块改成白块
    [self.collectionView reloadData];
    //主界面消失
    [UIView animateWithDuration:0.5 animations:^{
        _mainView.alpha = 0;
//        [_mainView removeFromSuperview];
    }];
    
}

#pragma mark - 初始化布局
- (void)setFlowLayout {
    
    //1.水平间距和垂直间距
    self.flowLayout.minimumLineSpacing = 1;
    self.flowLayout.minimumInteritemSpacing = 0;
    
    //2.得出块的大小
    //每一块的高度
    CGFloat itemHeight = (kScreenH - (kLineCount - 1) * self.flowLayout.minimumLineSpacing ) / 4;
    //块的大小,是屏幕中的大小是4*4的
    CGFloat itemWidth = kScreenW / kLineCount;
    _itemHeight = itemHeight;
    //-0.5的原因是为了让各个块在collectionView区分开来
    self.flowLayout.itemSize = CGSizeMake(itemWidth - 0.5 , itemHeight);
    
    //3.偏移量 (总高度 - 一个屏幕的高度) 总高度 = 50 * 块高度 + 49 * 行间距
    //也就是说让collectonView一开始就显示最下面一个屏幕
    
    
//    CGFloat offset = (kCellCount / kLineCount - 1) * self.flowLayout.minimumLineSpacing  + kCellCount / kLineCount * itemHeight - kScreenH;
//
//    [self.collectionView setContentOffset:CGPointMake(0, offset) animated:NO];
//    self.offsetTotal = offset;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:kCellCount - 1 inSection:0];
    
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    //4.其他的一些设置
    //不显示垂直方向的滚动条
    self.collectionView.showsVerticalScrollIndicator = NO;
    //取消弹簧效果
    self.collectionView.bounces = NO;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
