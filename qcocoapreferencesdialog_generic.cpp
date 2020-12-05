#include "stdafx.h"
#include "qcocoapreferencesdialog.h"

class QToolBarNoTooltips : public QToolBar
{
public :

    explicit QToolBarNoTooltips(QWidget *parent): QToolBar(parent)
    {

    }

    bool eventFilter(QObject *object, QEvent *e) override
    {
        if (e->type() == QEvent::ToolTip)
            return true;

        return QToolBar::eventFilter(object, e);
    }

protected:

    void resizeEvent(QResizeEvent *event) override
    {
        for (QToolButton* button : findChildren<QToolButton*>())
        {
            button->setToolTip(QString());
            button->installEventFilter(this);
        }

        QToolBar::resizeEvent(event);
    }
};

class QCocoaPreferencesPrivate
{
public:

    explicit QCocoaPreferencesPrivate(QCocoaPreferencesDialog *parent)
    {
        _toolbar = new QToolBarNoTooltips(parent);
        _toolbar->setFloatable(false);
        _toolbar->setMovable(false);
        _toolbar->setToolButtonStyle(Qt::ToolButtonTextUnderIcon);
        _toolbar->setIconSize(QSize(32, 32));
        _toolbar->move(_paddingLeft, _paddingTop);

        _actionGroup = new QActionGroup(_toolbar);
    }

    QCocoaPreferencesPrivate(const QCocoaPreferencesPrivate &c) = delete; // non construction-copyable
    QCocoaPreferencesPrivate& operator=(const QCocoaPreferencesPrivate&) = delete; // non copyable

    QToolBar *toolbar() const { return _toolbar; }
    QActionGroup *actionGroup() const { return _actionGroup; }

private:

    QToolBar *_toolbar = nullptr;
    QActionGroup *_actionGroup = nullptr;

    int _paddingLeft = 4;
    int _paddingTop = 0;
};

QCocoaToolbarImpl::QCocoaToolbarImpl(QCocoaPreferencesDialog *parent)
    : QObject(parent)
{
    _private = new QCocoaPreferencesPrivate(parent);

}

void QCocoaToolbarImpl::setButtonTitle(int nButton, const QString &title)
{

}

int QCocoaToolbarImpl::getHeight() const
{
    return _private->toolbar()->height();
}

int QCocoaToolbarImpl::getContentPaddingY() const
{
    return 0;
}

int QCocoaToolbarImpl::getMinimumWidth() const
{
    int nWidth = 0;

    for (QToolButton* button : _private->toolbar()->findChildren<QToolButton*>())
    {
        nWidth += button->width();
    }

    return nWidth;
}

QCocoaToolbarImpl::~QCocoaToolbarImpl()
{
    delete _private;
}

void QCocoaToolbarImpl::addButton(QPreferencesPage *page, bool bLast)
{
    QAction *pAction = _private->actionGroup()->addAction(page->getIcon(), page->getTitle());
    pAction->setCheckable(true);

    QObject::connect(pAction, &QAction::triggered, std::bind(&QCocoaToolbarImpl::buttonActivated, this, _private->actionGroup()->actions().size() - 1));

    if (bLast)
    {
        _private->toolbar()->addActions(_private->actionGroup()->actions());
        _private->toolbar()->adjustSize(); // must be here in order to have correct toolbar height
    }
}

void QCocoaToolbarImpl::setSelectedButton(int nButton)
{
    Q_ASSERT(nButton < _private->toolbar()->actions().size());

    if (nButton < _private->toolbar()->actions().size())
    {
        _private->toolbar()->actions().at(nButton)->setChecked(true);
    }
}
