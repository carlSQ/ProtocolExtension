//
//  NSObject+ProtocolExtension.h
//  Pods
//
//  Created by 沈强 on 2017/3/25.
//
//

#import <Foundation/Foundation.h>


#define extension(protocol) extern_extension(protocol)

#define extern_extension(_protocol) \
interface extension_concat(ProtocolExtension, extension_concat(_protocol, __extension__)) : NSObject<_protocol> @end\
@implementation extension_concat(ProtocolExtension, extension_concat(_protocol, __extension__))\
+ (void)load {\
  pe_addProtocolExtension(@protocol(_protocol),self);\
}


#define extension_concat2(A, B) A##B

#define extension_concat(A, B) extension_concat2(A, B)

void pe_addProtocolExtension(Protocol *protocol, Class extension);
