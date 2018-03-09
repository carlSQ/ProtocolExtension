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
#import "libffi/ffi.h"

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
    [exception raise];
#endif

    return;
  }
  [_extensions setValue:extension forKey:NSStringFromProtocol(protocol)];
  
}

static ffi_type* ffiTypeWithEncodingChar(const char *c) {
  switch (c[0]) {
    case 'v':
      return &ffi_type_void;
    case 'c':
      return &ffi_type_schar;
    case 'C':
      return &ffi_type_uchar;
    case 's':
      return &ffi_type_sshort;
    case 'S':
      return &ffi_type_ushort;
    case 'i':
      return &ffi_type_sint;
    case 'I':
      return &ffi_type_uint;
    case 'l':
      return &ffi_type_slong;
    case 'L':
      return &ffi_type_ulong;
    case 'q':
      return &ffi_type_sint64;
    case 'Q':
      return &ffi_type_uint64;
    case 'f':
      return &ffi_type_float;
    case 'd':
      return &ffi_type_double;
    case 'B':
      return &ffi_type_uint8;
    case '^':
      return &ffi_type_pointer;
    case '@':
      return &ffi_type_pointer;
    case ':':
      return &ffi_type_pointer;
    case '#':
      return &ffi_type_pointer;
  }
  return NULL;
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
  [self pe_forwardInvocation:anInvocation];
}

- (void)methodCall:(id)receiver method:(Method)method invocation:(NSInvocation *)anInvocation {
  IMP functionPtr = method_getImplementation(method);
  NSMethodSignature *methodSignature = [self methodSignatureForSelector:method_getName(method)];
  NSUInteger argsCount = methodSignature.numberOfArguments;
  ffi_type** ffiArgTypes = calloc(argsCount, sizeof(ffi_type *));
  void **ffiArgs = calloc(argsCount, sizeof(void *));
  for (int i = 0; i < argsCount ; i++) {
   const char *argType =  [methodSignature getArgumentTypeAtIndex:i];
    ffi_type* ftype = ffiTypeWithEncodingChar(argType);
    ffiArgTypes[i] = ftype;
    if (i == 0) {
      void **ffiArgPtr = calloc(1, ftype->size);
      *ffiArgPtr = (__bridge void *)receiver;
      ffiArgs[0] = ffiArgPtr;
    } else {
      void *ffiArgPtr = calloc(1, ftype->size);
      [anInvocation getArgument:ffiArgPtr atIndex:i];
      ffiArgs[i] = ffiArgPtr;
    }
    
  }
  ffi_cif cif;
  const char *returnType = [methodSignature methodReturnType];
  ffi_type *ffiReturnType = ffiTypeWithEncodingChar(returnType);
  ffi_status ffiStatus = ffi_prep_cif_var(&cif, FFI_DEFAULT_ABI, (unsigned int)0, (unsigned int)argsCount, ffiReturnType, ffiArgTypes);
  if (ffiStatus == FFI_OK) {
    if (returnType[0] == 'v') {
      ffi_call(&cif, functionPtr, NULL, ffiArgs);
    } else {
      void *returnPtr = NULL;
      if (ffiReturnType->size) {
        returnPtr = calloc(1, ffiReturnType->size);
      }
      ffi_call(&cif, functionPtr, returnPtr, ffiArgs);
      [anInvocation setReturnValue:returnPtr];
      free(returnPtr);
    }
  }
  free(ffiArgTypes);
  for (int i = 0; i < argsCount; i++) {
    free(ffiArgs[i]);
  }
  free(ffiArgs);
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

    unsigned int outCount = 0;
    Protocol * __unsafe_unretained * protocols = class_copyProtocolList(currentClass, &outCount);
    for (int i = 0; i < outCount; i++) {
      Protocol *protocol = protocols[i];
      [_protocolExtensions addObject:NSStringFromProtocol(protocol)];
    }
    free(protocols);

  NSMutableSet *extensionSets = [NSMutableSet setWithArray:_protocolExtensions];
  [extensionSets intersectSet:[NSSet setWithArray:protocolExtensions().allKeys]];
  return extensionSets.allObjects;
}

@end
