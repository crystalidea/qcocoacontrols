#include "pch.h"
#include "pool.h"

#import <Foundation/NSAutoreleasePool.h>

QMacAutoReleasePool::QMacAutoReleasePool()
    : pool([[NSAutoreleasePool alloc] init])
{

}

QMacAutoReleasePool::~QMacAutoReleasePool()
{
    [static_cast<NSAutoreleasePool *>(pool) drain];
}
