#ifndef qcocoamenubaricon_h
#define qcocoamenubaricon_h

// this class is currently a stub, to be implemented

class QCocoaMenubarItemPrivate;

class QCocoaMenubarItem : public QObject
{
public:

    QCocoaMenubarItem(QObject *parent);
    QCocoaMenubarItem(QObject *parent, WId existingStatusItem); // NSStatusItem *

    ~QCocoaMenubarItem();

#ifdef Q_OS_MAC
    WId getStatusItemButton() const; // NSButton *
#endif

protected:

private:

    QScopedPointer <QCocoaMenubarItemPrivate> pimpl;
};

#endif // qcocoamenubaricon_h
