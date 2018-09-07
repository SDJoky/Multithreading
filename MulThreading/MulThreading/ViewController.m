//
//  ViewController.m
//  MulThreading
//
//  Created by Joky_Lee on 2018/9/7.
//  Copyright © 2018年 Joky_Lee. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self test6];
//    [self test7];
//    [self test8];
}

//任务在主线程同步
- (void)test1
{
    NSLog(@"任务1");
    //2与3相互等待 造成死锁，阻塞 Thread 1: EXC_BAD_INSTRUCTION
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"任务2");
    });
    NSLog(@"任务3");
}

//加在同步全局队列中
- (void)test2
{
    NSLog(@"任务1");
    //同步线程在2完后继续执行3，全局并行队列2要先执行后回主队列执行3
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSLog(@"任务2");
    });
    NSLog(@"任务3");
    // 1->2->3
}

- (void)test3
{
    dispatch_queue_t queue = dispatch_queue_create("com.test3.serialQueue", DISPATCH_QUEUE_SERIAL);
    NSLog(@"任务1");
    dispatch_async(queue, ^{
        NSLog(@"任务2");
        //EXC_BAD_INSTRUCTION 死锁
        dispatch_sync(queue, ^{
            NSLog(@"任务3");
        });
        NSLog(@"任务4");
    });
    NSLog(@"任务5");
//    1->5.2不确定  3.4死锁
}

/*
 main: 1 异步线程 5
 异步线程: 2 同步线程 4
 */

- (void)test4
{
    NSLog(@"任务1");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"任务2");
        //3在5后面 没有了死锁，3后继续可执行4
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"任务3");
        });
        NSLog(@"任务4");
    });
    NSLog(@"任务5");
//    1->5.2->3->4
}

/*
 main: 异步线程 4 while 5
 异步线程: 1 同步线程（主队列） 3
 */
- (void)test5
{
    //任务4与1 并行 顺序不固定
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"任务1");
        //3在5后面 没有了死锁，3后继续可执行4
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"任务2");
        });
        NSLog(@"任务3");
    });
    NSLog(@"任务4");
    //死循环阻塞线程  则 5 2 3 均不执行
    while (1) {
        
    }
    NSLog(@"任务5");
}

- (void)test6
{
    NSLog(@"test6-任务A");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"test6-任务C");
    });
    NSLog(@"test6-任务B");
}

- (void)test7
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
        NSLog(@"test7-任务A");
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
        NSLog(@"test7-任务B");
    });
    
    dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
        NSLog(@"test7-任务C");
    });
}

- (void)test8
{
    dispatch_queue_t myQueue = dispatch_queue_create("concurrent.queue",DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(myQueue, ^{
        NSLog(@"test8-任务A");
    });
    
    dispatch_async(myQueue, ^{
        NSLog(@"test8-任务B");
    });
    //barrier之前的执行完 再执行后面的async,前后均异步无序
    dispatch_barrier_async(myQueue, ^{
        NSLog(@"test8-任务C");
    });
    
    dispatch_async(myQueue, ^{
        NSLog(@"test8-任务D");
    });
    
    dispatch_async(myQueue, ^{
        NSLog(@"test8-任务E");
    });
    
    
}



@end