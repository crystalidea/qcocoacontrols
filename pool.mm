#include "pch.h"
#include "pool.h"

#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)

    #import <Foundation/NSAutoreleasePool.h>

    QMacAutoReleasePool::QMacAutoReleasePool()
        : pool([[NSAutoreleasePool alloc] init])
    {

    }

    QMacAutoReleasePool::~QMacAutoReleasePool()
    {
        [static_cast<NSAutoreleasePool *>(pool) drain];
    }

#endif
