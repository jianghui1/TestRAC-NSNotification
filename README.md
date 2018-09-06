##### 熟悉`RAC`的，应该都知道它本身针对iOS系统类提供了许多类目用于增加方法，方便使用。但是，今天在使用`NSNotificationCenter+RACSupport`的时候遇到了坑，接下来便分享出来。

下面用到的完成测试用例[在这里](https://github.com/jianghui1/TestRAC-NSNotification)。

首页，建立两个页面A、B，然后A订阅通知，B发送通知，观察通知的传递。
当点击A中的按钮跳转的B的页面时，B发送通知，这时候A收到通知。日志如下
    
    2018-09-06 18:14:20.902227+0800 TestRAC+NSNotification[35033:8811463] A收到B的通知了
这时是没有问题的。

那如果这两个页面的通知顺序反过来呢？

新建C页面，并且在C页面订阅通知。然后先点击A页面按钮跳转到B，日志如下：

    2018-09-06 18:20:43.901481+0800 TestRAC+NSNotification[35325:8830635] A收到B的通知了
跟上一步一样，没有什么问题。接着继续点击按钮，跳转到C页面，然后返回到B页面，继续点击通知按钮，日志如下：

    2018-09-06 18:20:57.481049+0800 TestRAC+NSNotification[35325:8830635] A收到B的通知了
    2018-09-06 18:20:57.481345+0800 TestRAC+NSNotification[35325:8830635] C收到B的通知了

What?这是什么情况，为毛C也能收到通知。难道C没有被释放吗？

在C中添加如下代码：

    - (void)dealloc
    {
        NSLog(@"c挂了");
    }
重新运行，看看C有没有挂。当从C页面返回时，日志如下：

    2018-09-06 18:22:53.286350+0800 TestRAC+NSNotification[35424:8837258] c挂了

C页面确实挂了，但是仍旧能够收到通知信息。
接着点击通知按钮，整个过程的日志如下：

    2018-09-06 18:22:48.908253+0800 TestRAC+NSNotification[35424:8837258] A收到B的通知了
    2018-09-06 18:22:53.286350+0800 TestRAC+NSNotification[35424:8837258] c挂了
    2018-09-06 18:24:33.474609+0800 TestRAC+NSNotification[35424:8837258] A收到B的通知了
    2018-09-06 18:24:33.475009+0800 TestRAC+NSNotification[35424:8837258] C收到B的通知了

看到了吧，这就是我遇到的坑。那为什么会这个样子呢。其实是因为`rac_addObserverForName:`方法的实现：

    - (RACSignal *)rac_addObserverForName:(NSString *)notificationName object:(id)object {
    	@unsafeify(object);
    	return [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
    		@strongify(object);
    		id observer = [self addObserverForName:notificationName object:object queue:nil usingBlock:^(NSNotification *note) {
    			[subscriber sendNext:note];
    		}];
    
    		return [RACDisposable disposableWithBlock:^{
    			[self removeObserver:observer];
    		}];
    	}] setNameWithFormat:@"-rac_addObserverForName: %@ object: <%@: %p>", notificationName, [object class], object];
    }

这个方法返回一个信号，创建信号时通过`self`调用`addObserverForName:`方法订阅通知。接着返回一个清理对象，清理对象的工作是`removeObserver`。

对`addObserverForName:`方法不熟悉的可以看下方法的注释：

    - (id <NSObject>)addObserverForName:(nullable NSNotificationName)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(NSNotification *note))block API_AVAILABLE(macos(10.6), ios(4.0), watchos(2.0), tvos(9.0));
    // The return value is retained by the system, and should be held onto by the caller in
    // order to remove the observer with removeObserver: later, to stop observation.
    
返回一个被系统持有的对象，并且这个对象应当被调用者拿到，稍后用于调用`removeObserver:`方法将其移除来停止观察。

所以，既然上面的C中通知能够继续回调，证明`removeObserver:`没有被调用。为什么呢？

原因有两点。
1. 信号的创建中只调用了`sendNext:`方法，没有调用`sendError:` `sendCompleted`方法，所以清理对象的清理方法不会调用。
2. 这里的`self`为`[NSNotificationCenter defaultCenter]`对象，这个对象是单例对象，所以不会释放，这样清理对象也不会调用清理方法。

既然存在这种问题，那我们应该怎么解决呢？

其实我们可以直接使用`addObserverForName:` API，这样子我们既可以使用回调的方式处理通知，也可以取消通知的订阅。

新建D页面添加如下代码：

    - (void)viewDidLoad {
        [super viewDidLoad];
        
        __block id observer;
        observer = [[NSNotificationCenter defaultCenter] addObserverForName:@"B" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            NSLog(@"D收到B的通知了");
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }];
    }
    
    - (void)dealloc
    {
        NSLog(@"c挂了");
    }
同样的操作过程，打印日志如下：

    2018-09-06 18:44:22.613633+0800 TestRAC+NSNotification[36323:8903067] A收到B的通知了
    2018-09-06 18:44:26.360049+0800 TestRAC+NSNotification[36323:8903067] c挂了
    2018-09-06 18:44:27.021684+0800 TestRAC+NSNotification[36323:8903067] A收到B的通知了
    2018-09-06 18:44:28.830822+0800 TestRAC+NSNotification[36323:8903067] A收到B的通知了
    2018-09-06 18:44:29.302511+0800 TestRAC+NSNotification[36323:8903067] A收到B的通知了
    
可以看到，不管点击多少次按钮，D都不会接收到通知的。
