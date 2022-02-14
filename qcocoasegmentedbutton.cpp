#include "stdafx.h"
#include "qcocoasegmentedbutton.h"

#include <QToolButton>
#include <QHBoxLayout>

class QCocoaSegmentedButtonPrivate : public QObject
{
protected:

    QList<QToolButton*> m_pButtons;
    QSignalMapper *m_pSignalMapper;
    QPointer<QCocoaSegmentedButton> parent;
    QCocoaSegmentedButton::SegmentSwitchTracking m_trackingMode;
    QCocoaSegmentedButton::SegmentStyle m_Style;

public:
    QCocoaSegmentedButtonPrivate(QCocoaSegmentedButton *pParent)
        : QObject(pParent), parent(pParent)
    {
        m_pSignalMapper = new QSignalMapper(this);
        m_trackingMode = QCocoaSegmentedButton::NSSegmentSwitchTrackingSelectOne; // default
        m_Style = QCocoaSegmentedButton::SegmentStyleRounded; // default

        connect(m_pSignalMapper, SIGNAL(mapped(int)), pParent, SIGNAL(clicked(int)));
    }

    ~QCocoaSegmentedButtonPrivate()
    {
        delete m_pSignalMapper;
        qDeleteAll(m_pButtons);
    }

    friend class QCocoaSegmentedButton;
};

QCocoaSegmentedButton::QCocoaSegmentedButton(QWidget *pParent /*= 0*/)
  : QCocoaWidget(pParent)
{
    pimpl = new QCocoaSegmentedButtonPrivate(this);

    setTrackingMode(NSSegmentSwitchTrackingSelectOne); // default
    setSegmentStyle(SegmentStyleRounded); // default
}

void QCocoaSegmentedButton::setSegmentCount(int count)
{
    QHBoxLayout *layout = new QHBoxLayout(this);
    layout->setContentsMargins(QMargins(0, 0, 0, 0));
    layout->setSpacing(0);

    for (int i=0; i < count; ++i)
    {
        QToolButton *button = new QToolButton(this);
        button->setAutoRaise(true);
        button->setFocusPolicy(Qt::TabFocus);
        button->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
        pimpl->m_pButtons.append(button);
        layout->addWidget(button);
        connect(button, SIGNAL(clicked()), pimpl->m_pSignalMapper, SLOT(map()));
        pimpl->m_pSignalMapper->setMapping(button, i);
    }

    setTrackingMode(trackingMode()); // update tracking mode
    setSegmentStyle(segmentStyle()); // update style
}

QCocoaSegmentedButton::~QCocoaSegmentedButton()
{

}

void QCocoaSegmentedButton::setToolTip(int iSegment, const QString &strTip)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    pimpl->m_pButtons.at(iSegment)->setToolTip(strTip);
}

void QCocoaSegmentedButton::setSegmentIcon(int iSegment, const QIcon &icon)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    pimpl->m_pButtons.at(iSegment)->setIcon(icon);
}

#ifdef Q_OS_MAC

void QCocoaSegmentedButton::setSegmentIcon(int iSegment, CocoaStandardIcon icon)
{
    // Todo
}

#endif

void QCocoaSegmentedButton::setSegmentMenu(int iSegment, QMenu *menu)
{
    // TOdo
}

void QCocoaSegmentedButton::setEnabled(int iSegment, bool fEnabled)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    pimpl->m_pButtons.at(iSegment)->setEnabled(fEnabled);
}

void QCocoaSegmentedButton::animateClick(int iSegment)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    pimpl->m_pButtons.at(iSegment)->animateClick();
}

QSize QCocoaSegmentedButton::sizeHint() const
{
    return QWidget::sizeHint();
}

void QCocoaSegmentedButton::setChecked(int nIndex, bool bChecked)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    if (nIndex < pimpl->m_pButtons.size())
        pimpl->m_pButtons[nIndex]->setChecked(bChecked);
}

bool QCocoaSegmentedButton::isChecked(int nIndex) const
{
    if (nIndex < pimpl->m_pButtons.size())
        return pimpl->m_pButtons[nIndex]->isChecked();

    Q_ASSERT(0);

    return false;
}

void QCocoaSegmentedButton::setTitle(int iSegment, const QString &aTitle)
{
    QString textCropped = aTitle;

    static QFontMetrics fm(pimpl->m_pButtons[iSegment]->font());

    bool bCropped = false;

#if (QT_VERSION >= QT_VERSION_CHECK(5, 11, 0))
    while (fm.horizontalAdvance(textCropped) > pimpl->m_pButtons[iSegment]->width())
#else
    while (fm.width(textCropped) > pimpl->m_pButtons[iSegment]->width())
#endif  
    {
        textCropped = textCropped.left(textCropped.size() - 1);

        bCropped = true;
    }

    if (bCropped)
        textCropped = textCropped.left(textCropped.size() - 3) + "...";

    pimpl->m_pButtons.at(iSegment)->setText(textCropped);
}

void QCocoaSegmentedButton::setFixedWidth(int nSegment, int nWidth)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    if (nSegment < pimpl->m_pButtons.size() && nSegment >= 0)
        pimpl->m_pButtons[nSegment]->setFixedWidth(nWidth);
}

void QCocoaSegmentedButton::setTrackingMode(SegmentSwitchTracking mode)
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return;

    if (pimpl->m_pButtons.size())
    {
        bool bAutoExclusive = false;
        bool bCheckable = true;

        switch (mode)
        {
            case NSSegmentSwitchTrackingSelectOne:
            {
                bAutoExclusive = true;

                break;
            }

            case NSSegmentSwitchTrackingSelectAny:
            {
                break;
            }

            case NSSegmentSwitchTrackingMomentary:
            {
                bCheckable = false;

                break;
            }
        }

        for (int i = 0; i < pimpl->m_pButtons.size(); ++i)
        {
            pimpl->m_pButtons.at(i)->setAutoExclusive(bAutoExclusive);
            pimpl->m_pButtons.at(i)->setCheckable(bCheckable);
        }
    }

    pimpl->m_trackingMode = mode;
}

QCocoaSegmentedButton::SegmentSwitchTracking QCocoaSegmentedButton::trackingMode() const
{
    return pimpl->m_trackingMode;
}

void QCocoaSegmentedButton::setSegmentStyle(SegmentStyle style)
{
    if (style == SegmentStyleSmallSquare)
    {
        for (int i = 0; i < pimpl->m_pButtons.size(); ++i)
        {
            //setFixedWidth(i, 28);
        }
    }

    pimpl->m_Style = style;
}

QCocoaSegmentedButton::SegmentStyle QCocoaSegmentedButton::segmentStyle() const
{
    return pimpl->m_Style;
}

