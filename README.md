# ProtocolExtension

[![CI Status](http://img.shields.io/travis/yuzhoulangzik@126.com/ProtocolExtension.svg?style=flat)](https://travis-ci.org/yuzhoulangzik@126.com/ProtocolExtension)
[![Version](https://img.shields.io/cocoapods/v/ProtocolExtension.svg?style=flat)](http://cocoapods.org/pods/ProtocolExtension)
[![License](https://img.shields.io/cocoapods/l/ProtocolExtension.svg?style=flat)](http://cocoapods.org/pods/ProtocolExtension)
[![Platform](https://img.shields.io/cocoapods/p/ProtocolExtension.svg?style=flat)](http://cocoapods.org/pods/ProtocolExtension)

## Introduce
protocol extension for Objective-C like Swift

protocol 参数目前只支持Object

## Usage

定义protocol
```objc

@protocol PETest <NSObject>

@optional

- (id)test:(id)arg1 arg2:(id)arg2 arg3:(id)arg3;

@end

```

定义protocol 默认行为

```objc

@extension(PETest)


- (id)test:(id)arg1 arg2:(id)arg2 arg3:(id)arg3 {
NSLog(@"===================>%@===%@=====%@",arg1,arg2,arg3);
[self testLog];
return [NSObject new];
}

- (void)testLog {
NSLog(@"======================class: %@",self.class);
}

@end

```

具体使用

```objc


@interface PEProtocolTest : NSObject<PETest>

@end

@implementation PEProtocolTest

@end

...

[[PEProtocolTest new] test:@"xxxxxxxxxxxxx" arg2:@"yyyyyyyy" arg3:@"zzzzzzzzzzzz"];


```

结果

```objc

===================>xxxxxxxxxxxxx===yyyyyyyy=====zzzzzzzzzzzz

======================class: PEProtocolTest

```


```ruby
pod "ProtocolExtension"
```

## Author
carl shen

## License

ProtocolExtension is available under the MIT license. See the LICENSE file for more info.
