//
//  NSObject+ProtocolExtension.m
//  Pods
//
//  Created by 沈强 on 2017/3/25.
//
//

#import "NSObject+ProtocolExtension.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSMutableDictionary* protocolExtensions() {
  
  static NSMutableDictionary *_protocolExtensions = nil;
  static dispatch_once_t token;
  
  dispatch_once(&token, ^{
  
    _protocolExtensions = [NSMutableDictionary dictionary];
  });
  return _protocolExtensions;
}


void pe_addProtocolExtension(Protocol *protocol, Class extension) {
  
  NSMutableDictionary *_extensions = protocolExtensions();
  
  if ([_extensions.allKeys containsObject:NSStringFromProtocol(protocol)]) {
    
#if DEBUG
    
    NSException *exception = [NSException exceptionWithName:@"protocol extension" reason: [NSString stringWithFormat:@"has protocol extensions %@", NSStringFromProtocol(protocol)] userInfo:nil];
#endif

    return;
  }
 ;
  [_extensions setValue:extension forKey:NSStringFromProtocol(protocol)];
  
}


@implementation NSObject (ProtocolExtension)

+ (void)load {
  SEL interceptedSelectors[] = {
    @selector(forwardInvocation:),
    @selector(respondsToSelector:),
    @selector(methodSignatureForSelector:)
  };
  
  for (NSUInteger index = 0; index < sizeof(interceptedSelectors)/sizeof(SEL); ++index) {
    SEL originalSelector = interceptedSelectors[index];
    SEL swizzledSelector = NSSelectorFromString([@"pe_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
    Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
    method_exchangeImplementations(originalMethod, swizzledMethod);
  }
}

- (NSMethodSignature *)pe_methodSignatureForSelector:(SEL)aSelector {
  
  NSMethodSignature *methodSignature = [self pe_methodSignatureForSelector:aSelector];
  if (methodSignature) {
    return methodSignature;
  }
  
  for (NSString *protocol in [[self class] pe_protocolExtensions]) {
    Class extension = [protocolExtensions() objectForKey:protocol];
    if ([extension respondsToSelector:aSelector]) {
      return  [extension methodSignatureForSelector:aSelector];
    } else if([extension instancesRespondToSelector:aSelector]) {
      return [extension instanceMethodSignatureForSelector:aSelector];
    }
  }
  
  return nil;
  
}

- (void)pe_forwardInvocation:(NSInvocation *)anInvocation {
  
  if ([self pe_respondsToSelector:anInvocation.selector]) {
    [self pe_forwardInvocation:anInvocation];
    return;
  }
  
  for (NSString *protocol in [[self class] pe_protocolExtensions]) {
    Class extension = [protocolExtensions() objectForKey:protocol];
    if ([extension respondsToSelector:anInvocation.selector]) {
      Method method = class_getClassMethod(extension, anInvocation.selector);
      [self methodCall:self method:method invocation:anInvocation];
      return;
    } else if([extension instancesRespondToSelector:anInvocation.selector]) {
      Method method = class_getInstanceMethod(extension, anInvocation.selector);
      [self methodCall:self method:method invocation:anInvocation];
      return;
    }
  }
}

#define METHOD_INVOKE_CASE(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
  ReturnType result = ((ReturnType (*)(id, Method))methodInvoke)(receiver, method);\
  void *returnBuf = NULL;\
  if (!(returnBuf = realloc(returnBuf, returnSize))) {\
    return;\
  }\
\
  memcpy(returnBuf, &result,returnSize);\
  [anInvocation setReturnValue:returnBuf];\
  free(returnBuf);\
  return;\
}

#define METHOD_INVOKE_CASE_OBJECT(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id result = ((id (*)(id, Method))methodInvoke)(receiver, method);\
[anInvocation setReturnValue:&result];\
return;\
}

#define METHOD_INVOKE_CASE_1(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
CFRetain((__bridge CFTypeRef)(argBuf1));\
ReturnType result = ((ReturnType (*)(id, Method, id))methodInvoke)(receiver, method,argBuf1);\
void *returnBuf = NULL;\
if (!(returnBuf = realloc(returnBuf, returnSize))) {\
return;\
}\
memcpy(returnBuf, &result,returnSize);\
[anInvocation setReturnValue:returnBuf];\
free(returnBuf);\
return;\
}

#define METHOD_INVOKE_CASE_OBJECT_1(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
CFRetain((__bridge CFTypeRef)(argBuf1));\
id result = ((id (*)(id, Method, id))methodInvoke)(receiver, method,argBuf1);\
[anInvocation setReturnValue:&result];\
return;\
}


#define METHOD_INVOKE_CASE_2(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
ReturnType result = ((ReturnType (*)(id, Method, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2);\
void *returnBuf = NULL;\
if (!(returnBuf = realloc(returnBuf, returnSize))) {\
return;\
}\
memcpy(returnBuf, &result,returnSize);\
[anInvocation setReturnValue:returnBuf];\
free(returnBuf);\
return;\
}

#define METHOD_INVOKE_CASE_OBJECT_2(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
id result = ((id (*)(id, Method, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2);\
[anInvocation setReturnValue:&result];\
return;\
}

#define METHOD_INVOKE_CASE_3(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
id argBuf3 = nil;\
[anInvocation getArgument:&argBuf3 atIndex:4];\
CFRetain((__bridge CFTypeRef)(argBuf3));\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
ReturnType result = ((ReturnType (*)(id, Method, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3);\
void *returnBuf = NULL;\
if (!(returnBuf = realloc(returnBuf, returnSize))) {\
return;\
}\
memcpy(returnBuf, &result,returnSize);\
[anInvocation setReturnValue:returnBuf];\
free(returnBuf);\
return;\
}

#define METHOD_INVOKE_CASE_OBJECT_3(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
id argBuf3 = nil;\
[anInvocation getArgument:&argBuf3 atIndex:4];\
CFRetain((__bridge CFTypeRef)(argBuf3));\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
id result = ((id (*)(id, Method, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3);\
[anInvocation setReturnValue:&result];\
return;\
}


#define METHOD_INVOKE_CASE_4(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
id argBuf3 = nil;\
[anInvocation getArgument:&argBuf3 atIndex:4];\
id argBuf4 = nil;\
[anInvocation getArgument:&argBuf4 atIndex:5];\
CFRetain((__bridge CFTypeRef)(argBuf4));\
CFRetain((__bridge CFTypeRef)(argBuf3));\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
ReturnType result = ((ReturnType (*)(id, Method, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3, argBuf4);\
void *returnBuf = NULL;\
if (!(returnBuf = realloc(returnBuf, returnSize))) {\
return;\
}\
memcpy(returnBuf, &result,returnSize);\
[anInvocation setReturnValue:returnBuf];\
free(returnBuf);\
return;\
}

#define METHOD_INVOKE_CASE_OBJECT_4(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
id argBuf3 = nil;\
[anInvocation getArgument:&argBuf3 atIndex:4];\
id argBuf4 = nil;\
[anInvocation getArgument:&argBuf4 atIndex:5];\
CFRetain((__bridge CFTypeRef)(argBuf4));\
CFRetain((__bridge CFTypeRef)(argBuf3));\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
id result = ((id (*)(id, Method, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3, argBuf4);\
[anInvocation setReturnValue:&result];\
return;\
}


#define METHOD_INVOKE_CASE_5(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
id argBuf3 = nil;\
[anInvocation getArgument:&argBuf3 atIndex:4];\
id argBuf4 = nil;\
[anInvocation getArgument:&argBuf4 atIndex:5];\
id argBuf5 = nil;\
[anInvocation getArgument:&argBuf5 atIndex:6];\
CFRetain((__bridge CFTypeRef)(argBuf5));\
CFRetain((__bridge CFTypeRef)(argBuf4));\
CFRetain((__bridge CFTypeRef)(argBuf3));\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
ReturnType result = ((ReturnType (*)(id, Method, id, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3, argBuf4, argBuf5);\
void *returnBuf = NULL;\
if (!(returnBuf = realloc(returnBuf, returnSize))) {\
return;\
}\
memcpy(returnBuf, &result,returnSize);\
[anInvocation setReturnValue:returnBuf];\
free(returnBuf);\
return;\
}

#define METHOD_INVOKE_CASE_OBJECT_5(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
id argBuf3 = nil;\
[anInvocation getArgument:&argBuf3 atIndex:4];\
id argBuf4 = nil;\
[anInvocation getArgument:&argBuf4 atIndex:5];\
id argBuf5 = nil;\
[anInvocation getArgument:&argBuf5 atIndex:6];\
CFRetain((__bridge CFTypeRef)(argBuf5));\
CFRetain((__bridge CFTypeRef)(argBuf4));\
CFRetain((__bridge CFTypeRef)(argBuf3));\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
id result = ((id (*)(id, Method, id, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3, argBuf4, argBuf5);\
[anInvocation setReturnValue:&result];\
return;\
}

#define METHOD_INVOKE_CASE_6(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
id argBuf3 = nil;\
[anInvocation getArgument:&argBuf3 atIndex:4];\
id argBuf4 = nil;\
[anInvocation getArgument:&argBuf4 atIndex:5];\
id argBuf5 = nil;\
[anInvocation getArgument:&argBuf5 atIndex:6];\
id argBuf6 = nil;\
[anInvocation getArgument:&argBuf6 atIndex:7];\
CFRetain((__bridge CFTypeRef)(argBuf6));\
CFRetain((__bridge CFTypeRef)(argBuf5));\
CFRetain((__bridge CFTypeRef)(argBuf4));\
CFRetain((__bridge CFTypeRef)(argBuf3));\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
ReturnType result = ((ReturnType (*)(id, Method, id, id, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3, argBuf4, argBuf5, argBuf6);\
void *returnBuf = NULL;\
if (!(returnBuf = realloc(returnBuf, returnSize))) {\
return;\
}\
memcpy(returnBuf, &result,returnSize);\
[anInvocation setReturnValue:returnBuf];\
free(returnBuf);\
return;\
}

#define METHOD_INVOKE_CASE_OBJECT_6(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
id argBuf3 = nil;\
[anInvocation getArgument:&argBuf3 atIndex:4];\
id argBuf4 = nil;\
[anInvocation getArgument:&argBuf4 atIndex:5];\
id argBuf5 = nil;\
[anInvocation getArgument:&argBuf5 atIndex:6];\
id argBuf6 = nil;\
[anInvocation getArgument:&argBuf6 atIndex:7];\
CFRetain((__bridge CFTypeRef)(argBuf6));\
CFRetain((__bridge CFTypeRef)(argBuf5));\
CFRetain((__bridge CFTypeRef)(argBuf4));\
CFRetain((__bridge CFTypeRef)(argBuf3));\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
id result = ((id (*)(id, Method, id, id, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3, argBuf4, argBuf5, argBuf6);\
[anInvocation setReturnValue:&result];\
return;\
}

#define METHOD_INVOKE_CASE_7(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
id argBuf3 = nil;\
[anInvocation getArgument:&argBuf3 atIndex:4];\
id argBuf4 = nil;\
[anInvocation getArgument:&argBuf4 atIndex:5];\
id argBuf5 = nil;\
[anInvocation getArgument:&argBuf5 atIndex:6];\
id argBuf6 = nil;\
[anInvocation getArgument:&argBuf6 atIndex:7];\
id argBuf7 = nil;\
[anInvocation getArgument:&argBuf7 atIndex:8];\
CFRetain((__bridge CFTypeRef)(argBuf7));\
CFRetain((__bridge CFTypeRef)(argBuf6));\
CFRetain((__bridge CFTypeRef)(argBuf5));\
CFRetain((__bridge CFTypeRef)(argBuf4));\
CFRetain((__bridge CFTypeRef)(argBuf3));\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
ReturnType result = ((ReturnType (*)(id, Method, id, id, id, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3, argBuf4, argBuf5, argBuf6, argBuf7);\
void *returnBuf = NULL;\
if (!(returnBuf = realloc(returnBuf, returnSize))) {\
return;\
}\
memcpy(returnBuf, &result,returnSize);\
[anInvocation setReturnValue:returnBuf];\
free(returnBuf);\
return;\
}

#define METHOD_INVOKE_CASE_OBJECT_7(ReturnType)\
if(strcmp(returnType, @encode(ReturnType))==0) {\
id argBuf1 = nil;\
[anInvocation getArgument:&argBuf1 atIndex:2];\
id argBuf2 = nil;\
[anInvocation getArgument:&argBuf2 atIndex:3];\
id argBuf3 = nil;\
[anInvocation getArgument:&argBuf3 atIndex:4];\
id argBuf4 = nil;\
[anInvocation getArgument:&argBuf4 atIndex:5];\
id argBuf5 = nil;\
[anInvocation getArgument:&argBuf5 atIndex:6];\
id argBuf6 = nil;\
[anInvocation getArgument:&argBuf6 atIndex:7];\
id argBuf7 = nil;\
[anInvocation getArgument:&argBuf7 atIndex:8];\
CFRetain((__bridge CFTypeRef)(argBuf7));\
CFRetain((__bridge CFTypeRef)(argBuf6));\
CFRetain((__bridge CFTypeRef)(argBuf5));\
CFRetain((__bridge CFTypeRef)(argBuf4));\
CFRetain((__bridge CFTypeRef)(argBuf3));\
CFRetain((__bridge CFTypeRef)(argBuf2));\
CFRetain((__bridge CFTypeRef)(argBuf1));\
id result = ((id (*)(id, Method, id, id, id, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3, argBuf4, argBuf5, argBuf6, argBuf7);\
[anInvocation setReturnValue:&result];\
return;\
}


- (void)methodCall:(id)receiver method:(Method)method invocation:(NSInvocation *)anInvocation {
  
  [anInvocation retainArguments];
  IMP methodInvoke;
  methodInvoke = method_invoke;
  
#if !defined(__arm64__)
  char *typeDescription = method_copyReturnType(method);
  if (typeDescription[0] == '{') {
    //from jspatch
    //In some cases that returns struct, we should use the '_stret' API:
    //http://sealiesoftware.com/blog/archive/2008/10/30/objc_explain_objc_msgSend_stret.html
    //NSMethodSignature knows the detail but has no API to return, we can only get the info from debugDescription.
    NSMethodSignature *methodSignature = anInvocation.methodSignature;
    if ([methodSignature.debugDescription rangeOfString:@"is special struct return? YES"].location != NSNotFound) {
      methodInvoke = _objc_msgForward_stret;
    }
  }
  free(typeDescription);
#endif
  
  switch (anInvocation.methodSignature.numberOfArguments-2) {
    case 0:
    {
 
      const char *returnType = [anInvocation.methodSignature methodReturnType];
      
      NSUInteger returnSize;
      
      NSGetSizeAndAlignment(returnType, &returnSize, NULL);
    
      METHOD_INVOKE_CASE(UIEdgeInsets)
      METHOD_INVOKE_CASE(CGRect)
      METHOD_INVOKE_CASE(CGPoint)
      METHOD_INVOKE_CASE(CGSize)
      METHOD_INVOKE_CASE(CGAffineTransform)
      METHOD_INVOKE_CASE(UIOffset)
      METHOD_INVOKE_CASE(NSRange)
      METHOD_INVOKE_CASE(CGVector)
      METHOD_INVOKE_CASE(int)
      METHOD_INVOKE_CASE(double)
      METHOD_INVOKE_CASE(BOOL)
      METHOD_INVOKE_CASE(char)
      METHOD_INVOKE_CASE(float)
      METHOD_INVOKE_CASE(short)
      METHOD_INVOKE_CASE(unsigned short)
      METHOD_INVOKE_CASE(unsigned int)
      METHOD_INVOKE_CASE(unsigned long)
      METHOD_INVOKE_CASE(long long)
      METHOD_INVOKE_CASE(NSInteger)
      METHOD_INVOKE_CASE(CGFloat)
      METHOD_INVOKE_CASE_OBJECT(id)
      METHOD_INVOKE_CASE_OBJECT(Class)
      METHOD_INVOKE_CASE_OBJECT(void*)
      if(strcmp(returnType, @encode(void))==0) {
        ((void (*)(id, Method))methodInvoke)(receiver, method);
        return;
      }
      break;
    }
    case 1: {
      
      const char *returnType = [anInvocation.methodSignature methodReturnType];
      
      NSUInteger returnSize;
      
      NSGetSizeAndAlignment(returnType, &returnSize, NULL);
      
      METHOD_INVOKE_CASE_1(UIEdgeInsets)
      METHOD_INVOKE_CASE_1(CGRect)
      METHOD_INVOKE_CASE_1(CGPoint)
      METHOD_INVOKE_CASE_1(CGSize)
      METHOD_INVOKE_CASE_1(CGAffineTransform)
      METHOD_INVOKE_CASE_1(UIOffset)
      METHOD_INVOKE_CASE_1(NSRange)
      METHOD_INVOKE_CASE_1(CGVector)
      METHOD_INVOKE_CASE_1(int)
      METHOD_INVOKE_CASE_1(double)
      METHOD_INVOKE_CASE_1(BOOL)
      METHOD_INVOKE_CASE_1(char)
      METHOD_INVOKE_CASE_1(float)
      METHOD_INVOKE_CASE_1(short)
      METHOD_INVOKE_CASE_1(unsigned short)
      METHOD_INVOKE_CASE_1(unsigned int)
      METHOD_INVOKE_CASE_1(unsigned long)
      METHOD_INVOKE_CASE_1(long long)
      METHOD_INVOKE_CASE_1(NSInteger)
      METHOD_INVOKE_CASE_1(CGFloat)
      METHOD_INVOKE_CASE_OBJECT_1(id)
      METHOD_INVOKE_CASE_OBJECT_1(Class)
      METHOD_INVOKE_CASE_OBJECT_1(void*)
      if(strcmp(returnType, @encode(void))==0) {
        id argBuf1 = nil;
        [anInvocation getArgument:&argBuf1 atIndex:2];
        CFRetain((__bridge CFTypeRef)(argBuf1));
       ((void (*)(id, Method, id))methodInvoke)(receiver, method, argBuf1);
        return;
      }
      break;
    }
    case 2:{
      
      const char *returnType = [anInvocation.methodSignature methodReturnType];
      
      NSUInteger returnSize;
      
      NSGetSizeAndAlignment(returnType, &returnSize, NULL);
      
      METHOD_INVOKE_CASE_2(UIEdgeInsets)
      METHOD_INVOKE_CASE_2(CGRect)
      METHOD_INVOKE_CASE_2(CGPoint)
      METHOD_INVOKE_CASE_2(CGSize)
      METHOD_INVOKE_CASE_2(CGAffineTransform)
      METHOD_INVOKE_CASE_2(UIOffset)
      METHOD_INVOKE_CASE_2(NSRange)
      METHOD_INVOKE_CASE_2(CGVector)
      METHOD_INVOKE_CASE_2(int)
      METHOD_INVOKE_CASE_2(double)
      METHOD_INVOKE_CASE_2(BOOL)
      METHOD_INVOKE_CASE_2(char)
      METHOD_INVOKE_CASE_2(float)
      METHOD_INVOKE_CASE_2(short)
      METHOD_INVOKE_CASE_2(unsigned short)
      METHOD_INVOKE_CASE_2(unsigned int)
      METHOD_INVOKE_CASE_2(unsigned long)
      METHOD_INVOKE_CASE_2(long long)
      METHOD_INVOKE_CASE_2(NSInteger)
      METHOD_INVOKE_CASE_2(CGFloat)
      METHOD_INVOKE_CASE_OBJECT_2(id)
      METHOD_INVOKE_CASE_OBJECT_2(Class)
      METHOD_INVOKE_CASE_OBJECT_2(void*)
      if(strcmp(returnType, @encode(void))==0) {
        id argBuf1 = nil;
        [anInvocation getArgument:&argBuf1 atIndex:2];
        id argBuf2 = nil;
        [anInvocation getArgument:&argBuf2 atIndex:3];
        CFRetain((__bridge CFTypeRef)(argBuf2));
        CFRetain((__bridge CFTypeRef)(argBuf1));
        ((void (*)(id, Method, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2);
        return;
      }
      
      break;
    }
    case 3: {
      
      
      const char *returnType = [anInvocation.methodSignature methodReturnType];
      
      NSUInteger returnSize;
      
      NSGetSizeAndAlignment(returnType, &returnSize, NULL);
      
      METHOD_INVOKE_CASE_3(UIEdgeInsets)
      METHOD_INVOKE_CASE_3(CGRect)
      METHOD_INVOKE_CASE_3(CGPoint)
      METHOD_INVOKE_CASE_3(CGSize)
      METHOD_INVOKE_CASE_3(CGAffineTransform)
      METHOD_INVOKE_CASE_3(UIOffset)
      METHOD_INVOKE_CASE_3(NSRange)
      METHOD_INVOKE_CASE_3(CGVector)
      METHOD_INVOKE_CASE_3(int)
      METHOD_INVOKE_CASE_3(double)
      METHOD_INVOKE_CASE_3(BOOL)
      METHOD_INVOKE_CASE_3(char)
      METHOD_INVOKE_CASE_3(float)
      METHOD_INVOKE_CASE_3(short)
      METHOD_INVOKE_CASE_3(unsigned short)
      METHOD_INVOKE_CASE_3(unsigned int)
      METHOD_INVOKE_CASE_3(unsigned long)
      METHOD_INVOKE_CASE_3(long long)
      METHOD_INVOKE_CASE_3(NSInteger)
      METHOD_INVOKE_CASE_3(CGFloat)
      METHOD_INVOKE_CASE_OBJECT_3(id)
      METHOD_INVOKE_CASE_OBJECT_3(Class)
      METHOD_INVOKE_CASE_OBJECT_3(void*)
      if(strcmp(returnType, @encode(void))==0) {
        id argBuf1 = nil;
        [anInvocation getArgument:&argBuf1 atIndex:2];
        id argBuf2 = nil;
        [anInvocation getArgument:&argBuf2 atIndex:3];
        id argBuf3 = nil;
        [anInvocation getArgument:&argBuf3 atIndex:4];
        CFRetain((__bridge CFTypeRef)(argBuf3));
        CFRetain((__bridge CFTypeRef)(argBuf2));
        CFRetain((__bridge CFTypeRef)(argBuf1));
        ((void (*)(id, Method, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3);
        return;
      }
      
      break;
    }
    case 4: {
      
      
      const char *returnType = [anInvocation.methodSignature methodReturnType];
      
      NSUInteger returnSize;
      
      NSGetSizeAndAlignment(returnType, &returnSize, NULL);
      
      METHOD_INVOKE_CASE_4(UIEdgeInsets)
      METHOD_INVOKE_CASE_4(CGRect)
      METHOD_INVOKE_CASE_4(CGPoint)
      METHOD_INVOKE_CASE_4(CGSize)
      METHOD_INVOKE_CASE_4(CGAffineTransform)
      METHOD_INVOKE_CASE_4(UIOffset)
      METHOD_INVOKE_CASE_4(NSRange)
      METHOD_INVOKE_CASE_4(CGVector)
      METHOD_INVOKE_CASE_4(int)
      METHOD_INVOKE_CASE_4(double)
      METHOD_INVOKE_CASE_4(BOOL)
      METHOD_INVOKE_CASE_4(char)
      METHOD_INVOKE_CASE_4(float)
      METHOD_INVOKE_CASE_4(short)
      METHOD_INVOKE_CASE_4(unsigned short)
      METHOD_INVOKE_CASE_4(unsigned int)
      METHOD_INVOKE_CASE_4(unsigned long)
      METHOD_INVOKE_CASE_4(long long)
      METHOD_INVOKE_CASE_4(NSInteger)
      METHOD_INVOKE_CASE_4(CGFloat)
      METHOD_INVOKE_CASE_OBJECT_4(id)
      METHOD_INVOKE_CASE_OBJECT_4(Class)
      METHOD_INVOKE_CASE_OBJECT_4(void*)
      if(strcmp(returnType, @encode(void))==0) {
        id argBuf1 = nil;
        [anInvocation getArgument:&argBuf1 atIndex:2];
        id argBuf2 = nil;
        [anInvocation getArgument:&argBuf2 atIndex:3];
        id argBuf3 = nil;
        [anInvocation getArgument:&argBuf3 atIndex:4];
        id argBuf4 = nil;
        [anInvocation getArgument:&argBuf4 atIndex:5];
        CFRetain((__bridge CFTypeRef)(argBuf4));
        CFRetain((__bridge CFTypeRef)(argBuf3));
        CFRetain((__bridge CFTypeRef)(argBuf2));
        CFRetain((__bridge CFTypeRef)(argBuf1));
        ((void (*)(id, Method, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3,argBuf4);
        return;
      }
      
      break;
    }
    case 5:{
      
      
      const char *returnType = [anInvocation.methodSignature methodReturnType];
      
      NSUInteger returnSize;
      
      NSGetSizeAndAlignment(returnType, &returnSize, NULL);
      
      METHOD_INVOKE_CASE_5(UIEdgeInsets)
      METHOD_INVOKE_CASE_5(CGRect)
      METHOD_INVOKE_CASE_5(CGPoint)
      METHOD_INVOKE_CASE_5(CGSize)
      METHOD_INVOKE_CASE_5(CGAffineTransform)
      METHOD_INVOKE_CASE_5(UIOffset)
      METHOD_INVOKE_CASE_5(NSRange)
      METHOD_INVOKE_CASE_5(CGVector)
      METHOD_INVOKE_CASE_5(int)
      METHOD_INVOKE_CASE_5(double)
      METHOD_INVOKE_CASE_5(BOOL)
      METHOD_INVOKE_CASE_5(char)
      METHOD_INVOKE_CASE_5(float)
      METHOD_INVOKE_CASE_5(short)
      METHOD_INVOKE_CASE_5(unsigned short)
      METHOD_INVOKE_CASE_5(unsigned int)
      METHOD_INVOKE_CASE_5(unsigned long)
      METHOD_INVOKE_CASE_5(long long)
      METHOD_INVOKE_CASE_5(NSInteger)
      METHOD_INVOKE_CASE_5(CGFloat)
      METHOD_INVOKE_CASE_OBJECT_5(id)
      METHOD_INVOKE_CASE_OBJECT_5(Class)
      METHOD_INVOKE_CASE_OBJECT_5(void*)
      if(strcmp(returnType, @encode(void))==0) {
        id argBuf1 = nil;
        [anInvocation getArgument:&argBuf1 atIndex:2];
        id argBuf2 = nil;
        [anInvocation getArgument:&argBuf2 atIndex:3];
        id argBuf3 = nil;
        [anInvocation getArgument:&argBuf3 atIndex:4];
        id argBuf4 = nil;
        [anInvocation getArgument:&argBuf4 atIndex:5];
        id argBuf5 = nil;
        [anInvocation getArgument:&argBuf5 atIndex:6];
        CFRetain((__bridge CFTypeRef)(argBuf5));
        CFRetain((__bridge CFTypeRef)(argBuf4));
        CFRetain((__bridge CFTypeRef)(argBuf3));
        CFRetain((__bridge CFTypeRef)(argBuf2));
        CFRetain((__bridge CFTypeRef)(argBuf1));
        ((void (*)(id, Method, id, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3,argBuf4, argBuf5);
        return;
      }
      
      break;
    }
    case 6: {
      
      const char *returnType = [anInvocation.methodSignature methodReturnType];
      
      NSUInteger returnSize;
      
      NSGetSizeAndAlignment(returnType, &returnSize, NULL);
      
      METHOD_INVOKE_CASE_6(UIEdgeInsets)
      METHOD_INVOKE_CASE_6(CGRect)
      METHOD_INVOKE_CASE_6(CGPoint)
      METHOD_INVOKE_CASE_6(CGSize)
      METHOD_INVOKE_CASE_6(CGAffineTransform)
      METHOD_INVOKE_CASE_6(UIOffset)
      METHOD_INVOKE_CASE_6(NSRange)
      METHOD_INVOKE_CASE_6(CGVector)
      METHOD_INVOKE_CASE_6(int)
      METHOD_INVOKE_CASE_6(double)
      METHOD_INVOKE_CASE_6(BOOL)
      METHOD_INVOKE_CASE_6(char)
      METHOD_INVOKE_CASE_6(float)
      METHOD_INVOKE_CASE_6(short)
      METHOD_INVOKE_CASE_6(unsigned short)
      METHOD_INVOKE_CASE_6(unsigned int)
      METHOD_INVOKE_CASE_6(unsigned long)
      METHOD_INVOKE_CASE_6(long long)
      METHOD_INVOKE_CASE_6(NSInteger)
      METHOD_INVOKE_CASE_6(CGFloat)
      METHOD_INVOKE_CASE_OBJECT_6(id)
      METHOD_INVOKE_CASE_OBJECT_6(Class)
      METHOD_INVOKE_CASE_OBJECT_6(void*)
      if(strcmp(returnType, @encode(void))==0) {
        id argBuf1 = nil;
        [anInvocation getArgument:&argBuf1 atIndex:2];
        id argBuf2 = nil;
        [anInvocation getArgument:&argBuf2 atIndex:3];
        id argBuf3 = nil;
        [anInvocation getArgument:&argBuf3 atIndex:4];
        id argBuf4 = nil;
        [anInvocation getArgument:&argBuf4 atIndex:5];
        id argBuf5 = nil;
        [anInvocation getArgument:&argBuf5 atIndex:6];
        id argBuf6 = nil;
        [anInvocation getArgument:&argBuf6 atIndex:7];
        CFRetain((__bridge CFTypeRef)(argBuf6));
        CFRetain((__bridge CFTypeRef)(argBuf5));
        CFRetain((__bridge CFTypeRef)(argBuf4));
        CFRetain((__bridge CFTypeRef)(argBuf3));
        CFRetain((__bridge CFTypeRef)(argBuf2));
        CFRetain((__bridge CFTypeRef)(argBuf1));
        ((void (*)(id, Method, id, id, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3,argBuf4, argBuf5, argBuf6);
        return;
      }
      
      break;
    }
    case 7:{
      
      const char *returnType = [anInvocation.methodSignature methodReturnType];
      
      NSUInteger returnSize;
      
      NSGetSizeAndAlignment(returnType, &returnSize, NULL);
      
      METHOD_INVOKE_CASE_7(UIEdgeInsets)
      METHOD_INVOKE_CASE_7(CGRect)
      METHOD_INVOKE_CASE_7(CGPoint)
      METHOD_INVOKE_CASE_7(CGSize)
      METHOD_INVOKE_CASE_7(CGAffineTransform)
      METHOD_INVOKE_CASE_7(UIOffset)
      METHOD_INVOKE_CASE_7(NSRange)
      METHOD_INVOKE_CASE_7(CGVector)
      METHOD_INVOKE_CASE_7(int)
      METHOD_INVOKE_CASE_7(double)
      METHOD_INVOKE_CASE_7(BOOL)
      METHOD_INVOKE_CASE_7(char)
      METHOD_INVOKE_CASE_7(float)
      METHOD_INVOKE_CASE_7(short)
      METHOD_INVOKE_CASE_7(unsigned short)
      METHOD_INVOKE_CASE_7(unsigned int)
      METHOD_INVOKE_CASE_7(unsigned long)
      METHOD_INVOKE_CASE_7(long long)
      METHOD_INVOKE_CASE_7(NSInteger)
      METHOD_INVOKE_CASE_7(CGFloat)
      METHOD_INVOKE_CASE_OBJECT_7(id)
      METHOD_INVOKE_CASE_OBJECT_7(Class)
      METHOD_INVOKE_CASE_OBJECT_7(void*)
      if(strcmp(returnType, @encode(void))==0) {
        id argBuf1 = nil;
        [anInvocation getArgument:&argBuf1 atIndex:2];
        id argBuf2 = nil;
        [anInvocation getArgument:&argBuf2 atIndex:3];
        id argBuf3 = nil;
        [anInvocation getArgument:&argBuf3 atIndex:4];
        id argBuf4 = nil;
        [anInvocation getArgument:&argBuf4 atIndex:5];
        id argBuf5 = nil;
        [anInvocation getArgument:&argBuf5 atIndex:6];
        id argBuf6 = nil;
        [anInvocation getArgument:&argBuf6 atIndex:7];
        id argBuf7 = nil;
        [anInvocation getArgument:&argBuf7 atIndex:8];
        CFRetain((__bridge CFTypeRef)(argBuf7));
        CFRetain((__bridge CFTypeRef)(argBuf6));
        CFRetain((__bridge CFTypeRef)(argBuf5));
        CFRetain((__bridge CFTypeRef)(argBuf4));
        CFRetain((__bridge CFTypeRef)(argBuf3));
        CFRetain((__bridge CFTypeRef)(argBuf2));
        CFRetain((__bridge CFTypeRef)(argBuf1));
        ((void (*)(id, Method, id, id, id, id, id, id, id))methodInvoke)(receiver, method, argBuf1, argBuf2, argBuf3,argBuf4, argBuf5, argBuf6, argBuf7);
        return;
      }
      break;
    }
    default:
      break;
  }
}

- (BOOL)pe_respondsToSelector:(SEL)aSelector {
  if ([self pe_respondsToSelector:aSelector]) {
    return  YES;
  }
  return [self pe_extensionRespondsToSelector:aSelector];
}

- (BOOL)pe_extensionRespondsToSelector:(SEL)aSelector {
  for (NSString *protocol in [[self class] pe_protocolExtensions]) {
    if ([[protocolExtensions() objectForKey:protocol] respondsToSelector:aSelector]) {
      return YES;
    }
  }
  return NO;
}

+ (NSArray *)pe_protocolExtensions {
  
  NSMutableArray *_protocolExtensions = [NSMutableArray array];
  Class currentClass = [self class];

    int outCount = 0;
    Protocol * __unsafe_unretained * protocols = class_copyProtocolList(currentClass, &outCount);
    for (int i = 0; i < outCount; i++) {
      Protocol *protocol = protocols[i];
      [_protocolExtensions addObject:NSStringFromProtocol(protocol)];
    }
    free(protocols);

  NSMutableSet *extensionSets = [NSMutableSet setWithArray:_protocolExtensions];
  [extensionSets intersectSet:[NSSet setWithArray:protocolExtensions().allKeys]];
  return extensionSets;
}

@end
