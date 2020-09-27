#ifndef QCOCOABUTTON_P_H
#define QCOCOABUTTON_P_H

#import <AppKit/NSButton.h>

class QCocoaButton;

class CocoaButtonPrivate
{
public:

    CocoaButtonPrivate(QCocoaButton *parent, NSButton *customBtn = nullptr);
    virtual ~CocoaButtonPrivate();

    virtual void setImage(NSImage *img);
    void clicked();
    bool isSpecialButton(); // no title and icon

    virtual void updateSize();

    QCocoaButton *getButton() const { return _cocoaButton;}
    NSButton *getNSButton() const { return _nsButton;}

protected:

    QCocoaButton *_cocoaButton = nullptr;
    NSButton *_nsButton = nullptr;
};

#endif // QCOCOABUTTON_P_H
