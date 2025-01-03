#include "pch.h"
#include "pool.h"

#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)

    extern "C" {
        void *objc_autoreleasePoolPush(void);
        void objc_autoreleasePoolPop(void *pool);
    }

    QMacAutoReleasePool::QMacAutoReleasePool()
        : pool(objc_autoreleasePoolPush())
    {

    }

    QMacAutoReleasePool::~QMacAutoReleasePool()
    {
        objc_autoreleasePoolPop(pool);
    }

#endif
