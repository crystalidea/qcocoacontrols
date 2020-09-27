#include "stdafx.h"

#include "QCocoaButton.h"

#include <QToolBar>
#include <QToolButton>
#include <QPushButton>
#include <QVBoxLayout>

class CocoaButtonPrivate
{
public:
    CocoaButtonPrivate(QCocoaButton *button, QAbstractButton *abstractButton)
        : abstractButton(abstractButton) {}
    QPointer<QAbstractButton> abstractButton;
};

QCocoaButton::QCocoaButton(QWidget *parent)
    : QCocoaWidget(parent)
{
    QAbstractButton *button = nullptr;

    if (qobject_cast<QToolBar*>(parent))
        button = new QToolButton(this);
    else
    {
        QPushButton *pushBtn = new QPushButton(this);

        button = pushBtn;
    }

    connect(button, SIGNAL(clicked()), this, SIGNAL(clicked()));
    pimpl.reset(new CocoaButtonPrivate(this, button));

    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setMargin(0);
    layout->addWidget(button);
}

QCocoaButton::~QCocoaButton()
{

}

void QCocoaButton::setText(const QString &text)
{
    Q_ASSERT(pimpl);
    if (pimpl)
        pimpl->abstractButton->setText(text);
}

void QCocoaButton::setIcon(const QIcon &image)
{
    Q_ASSERT(pimpl);
    if (pimpl)
        pimpl->abstractButton->setIcon(image);
}

void QCocoaButton::setChecked(bool checked)
{
    Q_ASSERT(pimpl);
    if (pimpl)
        pimpl->abstractButton->setChecked(checked);
}

void QCocoaButton::setCheckable(bool checkable)
{
    Q_ASSERT(pimpl);
    if (pimpl)
        pimpl->abstractButton->setCheckable(checkable);
}

bool QCocoaButton::isChecked()
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return false;

    return pimpl->abstractButton->isChecked();
}

QSize QCocoaButton::sizeHint() const
{
    Q_ASSERT(pimpl);
    if (!pimpl)
        return QSize();

    return pimpl->abstractButton->sizeHint();
}

void QCocoaButton::setToolTip(const QString& strTip)
{
    Q_ASSERT(pimpl);
    if (pimpl)
        pimpl->abstractButton->setToolTip(strTip);
}

void QCocoaButton::setBezelStyle(BezelStyle)
{
    // only for mac
}

QAbstractButton *QCocoaButton::abstractButton()
{
    return pimpl->abstractButton;
}


void QCocoaButton::setIconPosition(IconPosition pos)
{
    if (pos == IconOnly)
    {
        setStyleSheet("QPushButton { text-align: left; }");
    }
}

void QCocoaButton::setMenu(QMenu *menu)
{
    QPushButton *btn = qobject_cast<QPushButton *>(pimpl->abstractButton);

    if (btn)
        btn->setMenu(menu);
}
