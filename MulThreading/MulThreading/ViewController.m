//
//  ViewController.m
//  MulThreading
//
//  Created by Joky_Lee on 2018/9/7.
//  Copyright © 2018年 Joky_Lee. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (nonatomic, strong) NSThread *expThread;
//copy修饰还是NSArray类型 增删改会崩溃
@property (nonatomic, copy) NSMutableArray *mutableArr;
@property (nonatomic, strong) NSMutableArray *mutableStrongArr;
//会跟随源数据变化
@property (nonatomic, strong) NSArray *sArr;
//不跟随源数据变化
@property (nonatomic, copy) NSArray *cArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self testArr];

//    让一个子线程不进入消亡状态，等待其他线程发来消息，处理其他事件
    self.expThread = [[NSThread alloc] initWithTarget:self selector:@selector(expRun) object:nil];
    [self.expThread start];
    [self test3];
//    往常驻线程发送消息
    [self performSelector:@selector(work) onThread:self.expThread withObject:nil waitUntilDone:NO];
    
//    常见的放卡顿操作
//    [self.imageView performSelector:@selector(setImage:) withObject:[UIImage imageNamed:@"01"] afterDelay:3.0 inModes:@[NSDefaultRunLoopMode]];
 

}

//深浅拷贝测试
- (void)testArr {

    self.mutableStrongArr = [NSMutableArray arrayWithObjects:[NSMutableString stringWithString:@"1"],@"2", nil];
    //    strong修饰的跟随源数据变化
    self.sArr = self.mutableStrongArr;
    //    copy修饰的不跟随源数据变化
    self.cArr = self.mutableStrongArr;
    [self.mutableStrongArr addObject:@"8"];

    NSLog(@"%@---%@---%@",self.sArr,self.cArr,self.mutableStrongArr);

    /*
        No1：可变对象的copy和mutableCopy方法都是深拷贝（区别完全深拷贝与单层深拷贝） 。

    　   No2：不可变对象的copy方法是浅拷贝，mutableCopy方法是深拷贝。

    　   No3：copy方法返回的对象都是不可变对象。
     */
    NSArray *arrayCopy = [self.mutableStrongArr copy];
    NSArray *arrayMutableCopy = [self.mutableStrongArr mutableCopy];
    NSMutableArray *mutableArrayCopy = [self.mutableStrongArr copy];
    NSMutableArray *mutableArrayMutableCopy = [self.mutableStrongArr mutableCopy];
    NSLog(@"array地址%p\n     arrayCopy地址%p \n     arrayMutableCopy地址%p \n    mutableArrayCopy地址%p \n   mutableArrayCopy地址%p\n",self.mutableStrongArr,arrayCopy,arrayMutableCopy,mutableArrayCopy,mutableArrayMutableCopy);
    NSLog(@"array = %@   arrayCopy = %@    arrayMutableCopy = %@   mutableArrayCopy =  %@    mutableArrayCopy =  %@",self.mutableStrongArr,arrayCopy,arrayMutableCopy,mutableArrayCopy,mutableArrayMutableCopy);

    NSMutableString *mustr = self.mutableStrongArr[0];
    [mustr appendString:@"2"];
    NSLog(@"-----改变后------");
    NSLog(@"%@---%@---%@",self.sArr,self.cArr,self.mutableStrongArr);
    NSLog(@"array = %@   arrayCopy = %@    arrayMutableCopy = %@   mutableArrayCopy =  %@    mutableArrayCopy =  %@",self.mutableStrongArr,arrayCopy,arrayMutableCopy,mutableArrayCopy,mutableArrayMutableCopy);
}

- (void)expRun {
    @autoreleasepool {
        // 添加port相当于添加Source 让线程不死
        [[NSRunLoop currentRunLoop] addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void)work {
    NSLog(@"常驻线程work");
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
        //EXC_BAD_INSTRUCTION 死锁 任务在同一个队列
//        dispatch_sync(queue, ^{
//            NSLog(@"任务3");
//        });
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
    NSLog(@"test5 start");
    //任务4与1 并行 顺序不固定 (41523 / 14523)
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"任务1");
        //3在5后面 没有了死锁
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"任务2");
        });
        NSLog(@"任务3");
    });
    NSLog(@"任务4");
    //死循环阻塞线程  则 5 2 3 均不执行
//    while (1) {
//
//    }
    NSLog(@"任务5");
}

- (void)test6
{
//    C最后执行
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"test6---任务C ");
    });
    
    NSLog(@"test6-任务A");
    
    NSLog(@"test6--任务B");
}

- (void)test7
{
//    AB无序 C结尾
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
        NSLog(@"test7-任务A");
    });
    
    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
        NSLog(@"test7--任务B");
    });
    
    dispatch_group_notify(group, dispatch_get_global_queue(0, 0), ^{
        NSLog(@"test7---任务C");
    });
}

- (void)test8
{
    NSLog(@"test8-Start");
    dispatch_queue_t myQueue = dispatch_queue_create("concurrent.queue",DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(myQueue, ^{
        NSLog(@"test8-任务A");
    });
   
    dispatch_async(myQueue, ^{
        NSLog(@"test8--任务B");
    });
    
    //barrier之前的执行完 再执行后面的async,前后均异步无序
    dispatch_barrier_async(myQueue, ^{
        NSLog(@"test8---任务C");
    });
    
    dispatch_async(myQueue, ^{
        NSLog(@"test8----任务D");
    });
    
    dispatch_async(myQueue, ^{
        NSLog(@"test8-----任务E");
    });
    
    NSLog(@"test8-End");
    
}



@end
