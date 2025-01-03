#pragma once

#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    class QMacAutoReleasePool
    {
    public:
        QMacAutoReleasePool();
        ~QMacAutoReleasePool();
    private:
        Q_DISABLE_COPY(QMacAutoReleasePool)
        void *pool;
    };
#endif

