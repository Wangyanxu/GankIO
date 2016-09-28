//
//  GKRealStuffViewController.m
//  GankIO
//
//  Created by Josscii on 16/7/23.
//  Copyright © 2016年 Josscii. All rights reserved.
//

#import "GKRealStuffViewController.h"
#import "GKRealStuffCell.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "GKRealStuffViewModel.h"
#import "GKAppConstants.h"
#import "GKHistoryViewController.h"
#import "KINWebBrowser/KINWebBrowserViewController.h"
#import "GKDBManager.h"
#import "GKRealStuffsContainerCell.h"

static NSString * const cellReuseIndentifier = @"GKRealStuffsContainerCell";

typedef void(^Block)(void);

@interface GKRealStuffViewController () <UITableViewDelegate, UITableViewDataSource, GKRealStuffProtocol>

@property (nonatomic, strong) GKRealStuffViewModel *viewModel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) Block moveCellBlock;
@property (nonatomic, assign) NSInteger currentIndex;

@end

@implementation GKRealStuffViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configureLayout];
    
    self.currentIndex = 0;
    
    self.viewModel = [[GKRealStuffViewModel alloc] init];
    
    RAC(self, navigationItem.title) = RACObserve(self.viewModel, title);
    
    @weakify(self)
    [[self.viewModel.requestRealStuffCommand.executionSignals switchToLatest] subscribeNext:^(NSArray *x) {
        @strongify(self)
        self.moveCellBlock();
        self.moveCellBlock = ^{
            @strongify(self)
            [self.tableView reloadData];
        };;
    }];
    
    [self.viewModel.requestRealStuffCommand.executing subscribeNext:^(NSNumber *x) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = x.boolValue;
    }];
    
    self.moveCellBlock = ^{
        @strongify(self)
        [self.tableView reloadData];
    };
    
    // 选择历史
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:GKDidPickAHistoryDayNotification object:nil]
      takeUntil:[self rac_willDeallocSignal]]
     subscribeNext:^(NSNotification *notifi) {
         @strongify(self)
         NSNumber *pickedIndex = notifi.userInfo[@"pickedIndex"];
         self.currentIndex = 0;
         self.viewModel.loadState = GKLoadStateRandom;
         [self.viewModel loadRealStuffAtOneDay:pickedIndex.integerValue];
    }];
    
    // notification
    [[[[NSNotificationCenter defaultCenter] rac_addObserverForName:GKDidSelectRealStuffNotification object:nil]
      takeUntil:[self rac_willDeallocSignal]]
     subscribeNext:^(NSNotification *notifi) {
         @strongify(self)
         NSString *url = notifi.userInfo[@"url"];
         KINWebBrowserViewController *webBrowser = [KINWebBrowserViewController webBrowser];
         webBrowser.hidesBottomBarWhenPushed = YES;
         [self.navigationController pushViewController:webBrowser animated:YES];
         [webBrowser loadURLString:url];
     }];
    
    [self.viewModel loadHistory];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"history"]) {
        UINavigationController *historyNav = (UINavigationController *)segue.destinationViewController;
        GKHistoryViewController *historyVC = (GKHistoryViewController *)historyNav.topViewController;
        historyVC.history = self.viewModel.history;
    }
}

- (void)configureLayout {
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // tableview
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.rowHeight = self.view.bounds.size.height;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[GKRealStuffsContainerCell class] forCellReuseIdentifier:cellReuseIndentifier];
    [self.view addSubview:self.tableView];
}

#pragma mark - protocol

- (void)loadNext {
    [self.viewModel loadNextRealStuff];
    @weakify(self)
    self.moveCellBlock = ^{
        @strongify(self)
        [self.tableView reloadData];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:++self.currentIndex inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
    };
}

- (void)loadPre {
    [self.viewModel loadPreRealStuff];
    @weakify(self)
    self.moveCellBlock = ^{
        @strongify(self)
        if (self.currentIndex == 0) {
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        } else {
            [self.tableView reloadData];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:--self.currentIndex inSection:0]  atScrollPosition:UITableViewScrollPositionNone animated:YES];
        }
    };
}

#pragma mark - tableview delegate and datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.realStuffs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GKRealStuffsContainerCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIndentifier forIndexPath:indexPath];
    cell.delegate = self;
    cell.realStuffs = self.viewModel.realStuffs[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    GKRealStuffsContainerCell *rfcell = [tableView dequeueReusableCellWithIdentifier:cellReuseIndentifier forIndexPath:indexPath];
    [rfcell.pullHeader stopLoading];
    [rfcell.pullFooter stopLoading];
}
@end
