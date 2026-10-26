#pragma once

// Qt 6 keeps its QMacAutoReleasePool private (qcore_mac_p.h), so the library
// carries its own class of the same name
class QMacAutoReleasePool
{
public:
    QMacAutoReleasePool();
    ~QMacAutoReleasePool();
private:
    Q_DISABLE_COPY(QMacAutoReleasePool)
    void *pool;
};

