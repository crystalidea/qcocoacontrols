#ifndef qcocoasegmentedbutton_h__
#define qcocoasegmentedbutton_h__

#include "qcocoawidget.h"
#include "qcocoaicon.h"
#include <QPointer>

class QCocoaSegmentedButtonPrivate;
class QMenu;

class QCocoaSegmentedButton: public QCocoaWidget
{
    Q_OBJECT

public:

    // matches NSSegmentStyle,
    // see: https://developer.apple.com/library/mac/documentation/cocoa/reference/applicationkit/Classes/NSSegmentedControl_Class/Art/NSSegmentStyle.jpg

    enum SegmentStyle {
        SegmentStyleRounded = 1,
        SegmentStyleTexturedRounded = 2,
        SegmentStyleRoundRect = 3,
        SegmentStyleTexturedSquare = 4,
        SegmentStyleCapsule = 5,
        SegmentStyleSmallSquare = 6,
    };

    // matches NSSegmentSwitchTracking
    enum SegmentSwitchTracking {
        NSSegmentSwitchTrackingSelectOne = 0, // Only one segment may be selected.
        NSSegmentSwitchTrackingSelectAny = 1, // Any segment can be selected
        NSSegmentSwitchTrackingMomentary = 2 // A segment is selected only when tracking.
    };

    QCocoaSegmentedButton(QWidget *pParent = nullptr);
    ~QCocoaSegmentedButton();

    QSize sizeHint() const;

    void setSegmentCount(int count);
    int segmentCount() const;

    void setTitle(int iSegment, const QString &strTitle);
    void setToolTip(int iSegment, const QString &strTip);
    void setSegmentIcon(int iSegment, const QIcon& icon);

#ifdef Q_OS_MAC
    void setSegmentIcon(int iSegment, QCocoaIcon::StandardIcon icon);
#endif

    void setSegmentMenu(int iSegment, QMenu *menu);

    void setEnabled(int iSegment, bool fEnabled);

    void animateClick(int iSegment);
    void onClicked(int iSegment);

    void setChecked(int nIndex, bool bChecked);
    bool isChecked(int nIndex) const;

    void setFixedWidth(int nSegment, int nWidth);
    int segmentWidth(int nSegment) const;

    void setTrackingMode(SegmentSwitchTracking mode);
    SegmentSwitchTracking trackingMode() const;

    void setSegmentStyle(SegmentStyle style);
    SegmentStyle segmentStyle() const;

signals:
    void clicked(int iSegment, bool fChecked = false);

private:

    void setCustomCellWithoutMenuDelay();

    friend class QCocoaSegmentedButtonPrivate;
    QPointer<QCocoaSegmentedButtonPrivate> pimpl;
};

#endif // qcocoasegmentedbutton_h__
