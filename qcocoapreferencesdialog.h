#ifndef qcocoapreferencesdialog_h__
#define qcocoapreferencesdialog_h__

#include <core_qt/QDialogEx.h>

class QCocoaPreferencesDialog;
class QPreferencesPage;

class QCocoaToolbarImpl : public QObject
{
    Q_OBJECT

public:

    QCocoaToolbarImpl(QCocoaPreferencesDialog *parent);
    ~QCocoaToolbarImpl();

    void addButton(QPreferencesPage *page, bool bLast);
    void setButtonTitle(int nButton, const QString &title);
    void setSelectedButton(int nButton);

    int getHeight() const;
    int getContentPaddingY() const;
    int getMinimumWidth() const; // depends on number of buttons

signals:

    void buttonActivated(int nButton);

private:

    class QCocoaPreferencesPrivate *_private = nullptr;
};

class QPreferencesPage : public QWidget
{
    Q_OBJECT

public:

    QPreferencesPage(QWidget *parent)
        : QWidget(parent)
    {

    }

    virtual QString getTitle() const = 0;
    virtual QIcon getIcon() const = 0;
    virtual void updateLayout() = 0;

signals:

    void preferencesChanged();
    void needRecalculateLayout();
};

class QCocoaPreferencesDialog : public QDialogEx
{
    Q_OBJECT

public:
    explicit QCocoaPreferencesDialog(QWidget *parent = nullptr);
    ~QCocoaPreferencesDialog();

    void addPage(QPreferencesPage *page, bool bLast = false);

    void setPrependingTitle(const QString &title) { _prependingTitle = title; }

protected slots:

    void toolbarButtonActivated(int nButton);
    void layoutChanged();

signals:

    void preferencesChanged();
    void currentPageChanged(int nPage);

protected:

    void setCurrentPage(int nButton, bool bAnimate);
    int getCurrentPage() const;

private:

    QCocoaToolbarImpl *_toolbar;
    QVector<QPreferencesPage *> _pages;
    int _currentPage;

    QString _prependingTitle;
};

#endif // qcocoapreferencesdialog_h__
