#include "stdafx.h"
#include "qcocoapreferencesdialog.h"

QCocoaPreferencesDialog::QCocoaPreferencesDialog(QWidget *parent, Qt::WindowFlags f) :
    QDialog(parent, f), _currentPage(0)
{
    setAttribute(Qt::WA_QuitOnClose, false);

    _toolbar = new QCocoaToolbarImpl(this);

    QObject::connect(_toolbar, &QCocoaToolbarImpl::buttonActivated, this, &QCocoaPreferencesDialog::toolbarButtonActivated);
}

void QCocoaPreferencesDialog::addPage(QPreferencesPage *page, bool bLast)
{
    if (!page)
        return;

    _toolbar->addButton(page, bLast);

    _pages.push_back(page);
    page->setParent(this);

    QObject::connect(page, &QPreferencesPage::preferencesChanged, this, &QCocoaPreferencesDialog::preferencesChanged);
    QObject::connect(page, &QPreferencesPage::needRecalculateLayout, this, &QCocoaPreferencesDialog::layoutChanged);

    if (bLast)
        setCurrentPage(0, false); // activate the first
}

void QCocoaPreferencesDialog::toolbarButtonActivated(int nButton)
{
    setCurrentPage(nButton, true);
}

void QCocoaPreferencesDialog::setCurrentPage(int nButton, bool bAnimate)
{
    for (auto w: _pages)
        w->setVisible(false);

    Q_ASSERT(nButton < _pages.size());

    if (nButton < _pages.size())
    {
        _currentPage = nButton;
        _toolbar->setSelectedButton(nButton);

        QPreferencesPage *page = _pages[_currentPage];

        page->updateLayout();
        page->setVisible(true);

        QSize pageSize = page->size();

        int nToolbarHeight = _toolbar->getHeight();
        int nContentPaddingY = _toolbar->getContentPaddingY();

        int nContentPaddingLeft = 40;
        int nContentPaddingRight = 20;

        int nDialogMinimumWidth = _toolbar->getMinimumWidth();
        int nContentWidth = nContentPaddingLeft + pageSize.width() + nContentPaddingRight;
        int nDialogWidth = qMax(nDialogMinimumWidth, nContentWidth);

        // no need to add toolbar height mac
        int nDialogHeight = nContentPaddingY * 2 + pageSize.height() + (nToolbarHeight ? nToolbarHeight : 0);

        QSize targetSize = QSize(nDialogWidth, nDialogHeight);

        if (targetSize != size())
        {
            if (bAnimate && isVisible())
            {
                QPropertyAnimation *animation = new QPropertyAnimation(this, "size");
                animation->setDuration(150);
                animation->setStartValue(size());
                animation->setEndValue(targetSize);
                animation->start();
            }
            else {
                QWidget::resize(targetSize);
            }
        }

        page->move(nContentPaddingLeft, nToolbarHeight + nContentPaddingY);

        QString dialogTitle;

        if (_prependingTitle.size())
            dialogTitle = _prependingTitle + QString(": ") + page->getTitle();
        else
            dialogTitle = page->getTitle();

        QWidget::setWindowTitle(dialogTitle);

        emit currentPageChanged(_currentPage);
    }
}

int QCocoaPreferencesDialog::getCurrentPage() const
{
    return _currentPage;
}

void QCocoaPreferencesDialog::layoutChanged()
{
    for (int i=0; i<_pages.size(); i++)
    {
        QPreferencesPage *page = _pages[i];

        _toolbar->setButtonTitle(i, page->getTitle());
    }

    setCurrentPage(getCurrentPage(), true);
}

QCocoaPreferencesDialog::~QCocoaPreferencesDialog()
{

}
