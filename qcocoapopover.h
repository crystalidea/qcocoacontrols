#ifndef MenuBarIconPopover_h
#define MenuBarIconPopover_h

class QCocoaPopoverPrivate;
class QCocoaMenubarItem;

// IMPORTANT NOTES
// 1. contentsWidget must be created without a parent widget (top level)
// 2. contentsWidget will be deleted after QCocoaPopover is destroyed
// 3. the class it not well tested and should be improved
// 4. currently no fallback for non mac systems is implemented
// 5. on Qt prior to 5.9.3 requires a patch, see QTBUG-63451

class QCocoaPopover : public QObject
{
    Q_OBJECT

public:

    enum class PopoverBehavior {
        ApplicationDefined = 0, // Your application assumes responsibility for closing the popover. AppKit will still close the popover in a limited number of circumstances. For instance, AppKit will attempt to close the popover when the window of its positioningView is closed.  The exact interactions in which AppKit will close the popover are not guaranteed.  You may consider implementing -cancel: to close the popover when the escape key is pressed.
        BehaviorTransient = 1, // (DEFAULT) AppKit will close the popover when the user interacts with a user interface element outside the popover.  Note that interacting with menus or panels that become key only when needed will not cause a transient popover to close.  The exact interactions that will cause transient popovers to close are not specified.
        BehaviorSemitransient = 2 // AppKit will close the popover when the user interacts with user interface elements in the window containing the popover's positioning view.  Semi-transient popovers cannot be shown relative to views in other popovers, nor can they be shown relative to views in child windows.  The exact interactions that cause semi-transient popovers to close are not specified.
    };

    QCocoaPopover(QObject *parent, QWidget *contents);
    ~QCocoaPopover();

    void show(QWidget *forWidget);
    void show(QCocoaMenubarItem *forMenuIcon);

    void close();

    void setPopoverBehavior(PopoverBehavior b);
    void setAnimate(bool bAnimate);

    void setTimeout(int msec) {
        _timeout = msec;
    }

protected:

    bool eventFilter(QObject *obj, QEvent *event) override;

signals:

    void closed(); // TODO

private:

    int _timeout = 0;

    QWidget *_contents;

    QScopedPointer<QCocoaPopoverPrivate> p;

    friend class QCocoaPopoverPrivate;
};

#endif // MenuBarIconPopover_h
