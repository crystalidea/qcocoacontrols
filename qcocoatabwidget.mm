#include "pch.h"
#include "qcocoatabwidget.h"
#include "qcocoaappearance.h"

#import <AppKit/AppKit.h>

#include <functional>

// The bar follows NSTabView, whose bar has the tabs role from macOS 27 on, which the macOS 27 SDK declares. Built with
// an older SDK the class stays a plain QTabWidget: on macOS 27 the bar would have no role, unlike the bar of NSTabView
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 270000
#define QCOCOATABWIDGET_NATIVE_BAR
#endif

// The view the native bar lies in. NSTabView puts its bar at a fraction of a point, while a widget lies at whole
// points: this view covers the bar up to the next whole points and keeps it at the fraction, counting from the top
// like NSTabView does
@interface QCocoaTabBarHost : NSView
@end

@implementation QCocoaTabBarHost
- (BOOL)isFlipped
{
    return YES;
}
@end

@interface QCocoaTabBarTarget : NSObject
{
@public
    std::function<void(NSInteger)> selected;
}
- (void)segmentSelected:(NSSegmentedControl *)sender;
@end

@implementation QCocoaTabBarTarget
- (void)segmentSelected:(NSSegmentedControl *)sender
{
    if (selected)
        selected(sender.selectedSegment);
}
@end

namespace
{
    NSControlSize controlSizeOf(const QWidget *widget)
    {
        if (widget->testAttribute(Qt::WA_MacMiniSize))
            return NSControlSizeMini;

        if (widget->testAttribute(Qt::WA_MacSmallSize))
            return NSControlSizeSmall;

        return NSControlSizeRegular;
    }

    NSFont *fontOf(NSControlSize size)
    {
        return [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:size]];
    }

    // A tab title as the bar shows it: macOS shows no mnemonics, and "&&" stands for one ampersand
    NSString *titleOf(const QString &text)
    {
        QString title;
        title.reserve(text.size());

        for (qsizetype i = 0; i < text.size(); ++i)
        {
            if (text.at(i) != u'&')
                title += text.at(i);
            else if (i + 1 < text.size() && text.at(i + 1) == u'&')
                title += text.at(++i);
        }

        return title.toNSString();
    }

    // An icon of the given size in points, with the pixels of 1x and 2x screens
    NSImage *imageOf(const QIcon &icon, const QSize &size)
    {
        NSImage *image = [[[NSImage alloc] initWithSize:size.toCGSize()] autorelease];

        for (const qreal scale : {1.0, 2.0})
        {
            const QImage pixels = icon.pixmap(size, scale).toImage();

            if (pixels.isNull())
                continue;

            CGImageRef cgImage = pixels.toCGImage();
            NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
            CGImageRelease(cgImage);

            rep.size = size.toCGSize();
            [image addRepresentation:rep];
            [rep release];
        }

        return image;
    }

    // The whole points that cover a rect
    QRect coveringRect(const QRectF &rect)
    {
        const int left = qFloor(rect.left());
        const int top = qFloor(rect.top());

        return QRect(left, top, qCeil(rect.right()) - left, qCeil(rect.bottom()) - top);
    }

    // The appearance of the window of the widget, without creating a native window for it
    NSAppearance *appearanceOf(const QWidget *widget)
    {
        if (const QWindow *window = widget->window()->windowHandle())
            if (window->handle())
                return reinterpret_cast<NSView *>(window->winId()).effectiveAppearance;

        return NSApp.effectiveAppearance;
    }
}

class QCocoaTabBar;

class QCocoaTabWidgetPrivate
{
public:

    // Where NSTabView puts its bar and its pages in a widget of a given size, in the coordinates of the widget
    struct Layout
    {
        QRectF bar; // the native bar, as wide as its tabs need
        QRectF offscreenBar; // the bar of the offscreen tab view, under which its bezel is open
        QRect contents;
        QRect alignment; // the rect other controls line up with: the bezel and the bar
    };

    explicit QCocoaTabWidgetPrivate(QCocoaTabWidget *tabWidget);
    ~QCocoaTabWidgetPrivate();

    Layout layout(const QSize &size) const;
    QMargins contentsMargins() const;
    void paintPane(QPainter *painter) const;

    // The offscreen tab view takes the titles of the bar and its control size
    void update(NSArray<NSString *> *titles, NSControlSize size);

    QCocoaTabWidget *const tabWidget;
    QCocoaTabBar *bar = nullptr;
    QStyle *style = nullptr;

private:

    // Never shown: it lays out the bar and the pages and draws the bezel of the pane
    NSTabView *_metrics = nil;

    mutable QImage _pane;
    mutable QString _paneKey;
    int _generation = 0;
};

// QTabBar keeps the tabs and the current one, the native bar shows them and takes the clicks. The QTabBar is laid out
// like any tab bar, as it is the one QTabWidget knows, but paints nothing: the native bar covers it
class QCocoaTabBar : public QTabBar
{
public:

    explicit QCocoaTabBar(QCocoaTabWidgetPrivate *d)
        : _d(d)
    {
        QMacAutoReleasePool pool;

        _control = [[NSSegmentedControl alloc] initWithFrame:NSZeroRect];
        _control.trackingMode = NSSegmentSwitchTrackingSelectOne;
#ifdef QCOCOATABWIDGET_NATIVE_BAR
        if (@available(macOS 27, *))
            _control.role = NSSegmentedControlRoleTabs;
#endif
        // the keyboard focus stays with the Qt widgets when the bar is clicked
        _control.refusesFirstResponder = YES;

        _target = [[QCocoaTabBarTarget alloc] init];
        _target->selected = [this](NSInteger segment) { select(segment); };
        _control.target = _target;
        _control.action = @selector(segmentSelected:);

        _host = [[QCocoaTabBarHost alloc] initWithFrame:NSZeroRect];
        [_host addSubview:_control];

        _container = QWidget::createWindowContainer(QWindow::fromWinId(WId(_host)), this);
        _container->setAttribute(Qt::WA_NativeWindow);

        setDrawBase(false);
        setExpanding(false);
        setUsesScrollButtons(false);
        setElideMode(Qt::ElideNone);
        setFocusPolicy(Qt::NoFocus);

        connect(this, &QTabBar::currentChanged, this, [this] { selectCurrent(); });
    }

    ~QCocoaTabBar() override
    {
        _control.target = nil;
        _target->selected = nullptr;

        [_target release];
        [_control release];
        [_host release];
    }

    // The tab widget is destroyed before its children
    void detach()
    {
        _d = nullptr;
    }

    NSSize controlSize() const
    {
        return _control.fittingSize;
    }

    // The title of each segment
    NSArray<NSString *> *titles() const
    {
        NSMutableArray<NSString *> *titles = [NSMutableArray array];

        for (NSInteger segment = 0; segment < _control.segmentCount; ++segment)
            [titles addObject:[_control labelForSegment:segment] ?: @""];

        return titles;
    }

    // The width the bar takes in the tab widget, and one more point, as the bar lies at a fraction of a point. The
    // tab view lays it out in a width that holds any bar, so that it doesn't squeeze its tabs
    QSize sizeHint() const override
    {
        const NSSize size = controlSize();
        const qreal width = _d && _d->bar == this ? _d->layout(QSize(4000, 300)).bar.width() : size.width;

        return QSize(qCeil(width) + 1, qCeil(size.height) + 1);
    }

    QSize minimumSizeHint() const override
    {
        return sizeHint();
    }

    // Gives the native bar the tabs of QTabBar
    void sync()
    {
        _syncQueued = false;

        if (!_d || _d->bar != this)
            return;

        QMacAutoReleasePool pool;

        bool resized = false;
        const NSControlSize size = controlSizeOf(_d->tabWidget);

        if (_size != int(size))
        {
            _control.controlSize = size;
            _control.font = fontOf(size);
            _size = int(size);
            resized = true;
        }

        QList<int> tabs;

        for (int tab = 0; tab < count(); ++tab)
        {
            if (isTabVisible(tab))
                tabs.append(tab);
        }

        if (_control.segmentCount != tabs.size())
        {
            _control.segmentCount = tabs.size();
            _icons.clear();
            resized = true;
        }

        _icons.resize(tabs.size());

        const QSize iconSize = this->iconSize().isValid() ? this->iconSize() : QSize(16, 16);

        for (qsizetype segment = 0; segment < tabs.size(); ++segment)
        {
            const int tab = tabs.at(segment);
            NSString *title = titleOf(tabText(tab));

            if (![title isEqualToString:[_control labelForSegment:segment] ?: @""])
            {
                [_control setLabel:title forSegment:segment];
                resized = true;
            }

            const QIcon icon = tabIcon(tab);
            const qint64 key = icon.isNull() ? 0 : icon.cacheKey();

            if (_icons.at(segment) != key)
            {
                [_control setImage:icon.isNull() ? nil : imageOf(icon, iconSize) forSegment:segment];
                _icons[segment] = key;
                resized = true;
            }

            [_control setEnabled:isTabEnabled(tab) forSegment:segment];

            const QString tip = tabToolTip(tab);
            [_control setToolTip:tip.isEmpty() ? nil : tip.toNSString() forSegment:segment];
        }

        _tabs = tabs;
        _control.enabled = isEnabled();
        _host.hidden = tabs.isEmpty();
        selectCurrent();

        if (resized)
        {
            _d->update(titles(), size);
            updateGeometry();
        }

        place();
    }

protected:

    void paintEvent(QPaintEvent *) override
    {
        // QTabBar repaints, rather than lays out again, when a tab gets enabled or disabled; the native bar learns
        // about it here, once the change is complete
        if (!_syncQueued)
        {
            _syncQueued = true;
            QMetaObject::invokeMethod(this, [this] { sync(); }, Qt::QueuedConnection);
        }
    }

    void tabInserted(int) override
    {
        sync();
    }

    void tabRemoved(int) override
    {
        sync();
    }

    void tabLayoutChange() override
    {
        sync();
    }

    void changeEvent(QEvent *event) override
    {
        QTabBar::changeEvent(event);

        if (event->type() == QEvent::EnabledChange)
            sync();
    }

    void resizeEvent(QResizeEvent *event) override
    {
        QTabBar::resizeEvent(event);
        place();
    }

    void moveEvent(QMoveEvent *event) override
    {
        QTabBar::moveEvent(event);
        place();
    }

private:

    void select(NSInteger segment)
    {
        if (segment < 0 || segment >= _tabs.size())
            return;

        const int tab = _tabs.at(segment);

        emit tabBarClicked(tab);
        setCurrentIndex(tab);
    }

    void selectCurrent()
    {
        const NSInteger segment = _tabs.indexOf(currentIndex());

        if (_control.selectedSegment != segment)
            _control.selectedSegment = segment;
    }

    // The native bar where NSTabView puts it, within the whole points of this widget
    void place()
    {
        if (!_d || _d->bar != this)
            return;

        const QRectF bar = _d->layout(_d->tabWidget->size()).bar.translated(-QPointF(pos()));

        _container->setGeometry(rect());
        _control.frame = bar.toCGRect();
    }

    QCocoaTabWidgetPrivate *_d;

    NSSegmentedControl *_control = nil;
    QCocoaTabBarHost *_host = nil;
    QCocoaTabBarTarget *_target = nil;
    QWidget *_container = nullptr;

    QList<int> _tabs; // the tab of each segment: a hidden tab has none
    QList<qint64> _icons; // the cache keys of the icons on the segments
    int _size = -1; // the NSControlSize the bar has
    bool _syncQueued = false;
};

// QTabWidget lays out its bar and its pages and paints its pane through its style. This one, set on the tab widget
// alone, puts them where NSTabView puts them and paints the bezel of NSTabView; everything else, the pages included,
// keeps the style of the app
class QCocoaTabWidgetStyle : public QProxyStyle
{
public:

    explicit QCocoaTabWidgetStyle(QCocoaTabWidgetPrivate *d)
        : QProxyStyle(QApplication::style()->name()), _d(d)
    {

    }

    QRect subElementRect(SubElement element, const QStyleOption *option, const QWidget *widget) const override
    {
        if (widget != _d->tabWidget)
            return QProxyStyle::subElementRect(element, option, widget);

        switch (element)
        {
        case SE_TabWidgetTabBar:
            return coveringRect(_d->layout(option->rect.size()).bar);

        case SE_TabWidgetTabPane:
            return option->rect; // paintPane() puts the bezel where NSTabView has it

        case SE_TabWidgetTabContents:
            return _d->layout(option->rect.size()).contents;

        case SE_TabWidgetLayoutItem:
            return _d->layout(option->rect.size()).alignment;

        case SE_TabWidgetLeftCorner:
        case SE_TabWidgetRightCorner:
            return QRect();

        default:
            return QProxyStyle::subElementRect(element, option, widget);
        }
    }

    QSize sizeFromContents(ContentsType type, const QStyleOption *option, const QSize &size,
                           const QWidget *widget) const override
    {
        if (type != CT_TabWidget || widget != _d->tabWidget)
            return QProxyStyle::sizeFromContents(type, option, size, widget);

        // QTabWidget passes the size of the pages with the bar on top of them, and the margins of NSTabView take the
        // place of the bar
        const auto *frame = qstyleoption_cast<const QStyleOptionTabWidgetFrame *>(option);
        const int bar = frame ? frame->tabBarSize.height() : 0;
        const QMargins margins = _d->contentsMargins();

        return QSize(size.width() + margins.left() + margins.right(),
                     size.height() - bar + margins.top() + margins.bottom());
    }

    void drawPrimitive(PrimitiveElement element, const QStyleOption *option, QPainter *painter,
                       const QWidget *widget) const override
    {
        if (element == PE_FrameTabWidget && widget == _d->tabWidget)
            _d->paintPane(painter);
        else
            QProxyStyle::drawPrimitive(element, option, painter, widget);
    }

private:

    QCocoaTabWidgetPrivate *_d;
};

QCocoaTabWidgetPrivate::QCocoaTabWidgetPrivate(QCocoaTabWidget *tabWidget)
    : tabWidget(tabWidget)
{
    _metrics = [[NSTabView alloc] initWithFrame:NSMakeRect(0, 0, 300, 100)];

    style = new QCocoaTabWidgetStyle(this);
    bar = new QCocoaTabBar(this);
}

QCocoaTabWidgetPrivate::~QCocoaTabWidgetPrivate()
{
    delete style;
    [_metrics release];
}

QCocoaTabWidgetPrivate::Layout QCocoaTabWidgetPrivate::layout(const QSize &size) const
{
    QMacAutoReleasePool pool;

    _metrics.frame = NSMakeRect(0, 0, qMax(size.width(), 0), qMax(size.height(), 0));
    [_metrics layoutSubtreeIfNeeded];

    Layout layout;

    for (NSView *view in _metrics.subviews)
    {
        if ([view isKindOfClass:[NSSegmentedControl class]])
            layout.offscreenBar = QRectF::fromCGRect(view.frame);
    }

    // The native bar is as wide as the bar of NSTabView, which on macOS 26 gives each tab more room than the
    // segmented control needs: the control shares the extra width out among its tabs. Icons, which the offscreen tab
    // view doesn't show, can make the native bar wider still. It is centered like the bar of NSTabView; titles give
    // it widths in fractions of a point, and it starts at a whole pixel of the screen
    const NSSize barSize = bar ? bar->controlSize() : NSZeroSize;
    const qreal barWidth = qMax<qreal>(barSize.width, layout.offscreenBar.width());
    const qreal scale = tabWidget->devicePixelRatioF();
    const auto pixel = [scale](qreal value) { return qRound(value * scale) / scale; };

    layout.bar = QRectF(pixel((size.width() - barWidth) / 2), pixel(layout.offscreenBar.top()), barWidth,
                        barSize.height);

    const QRect contents = QRectF::fromCGRect(_metrics.contentRect).toRect();
    layout.contents = QRect(contents.topLeft(), contents.size().expandedTo(QSize(0, 0)));

    const NSEdgeInsets insets = _metrics.alignmentRectInsets;
    layout.alignment = QRect(QPoint(0, 0), size).marginsRemoved(
        QMargins(qRound(insets.left), qRound(insets.top), qRound(insets.right), qRound(insets.bottom)));

    return layout;
}

QMargins QCocoaTabWidgetPrivate::contentsMargins() const
{
    // the margins don't depend on the size, any size that holds the bar gives them
    const QSize size(400, 300);
    const QRect contents = layout(size).contents;

    return QMargins(contents.left(), contents.top(), size.width() - contents.left() - contents.width(),
                    size.height() - contents.top() - contents.height());
}

void QCocoaTabWidgetPrivate::paintPane(QPainter *painter) const
{
    QMacAutoReleasePool pool;

    const QSize size = tabWidget->size();
    const qreal scale = tabWidget->devicePixelRatioF();

    if (size.isEmpty())
        return;

    NSAppearance *appearance = appearanceOf(tabWidget);
    const Layout layout = this->layout(size);

    const QString key = QStringLiteral("%1 %2x%3@%4 %5").arg(_generation).arg(size.width()).arg(size.height())
                            .arg(scale).arg(QString::fromNSString(appearance.name));

    if (key != _paneKey)
    {
        // the offscreen tab view draws its bezel in the appearance of the window, in sRGB like the backing store of
        // Qt, and at the resolution of the screen
        NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc]
            initWithBitmapDataPlanes:nullptr pixelsWide:qCeil(size.width() * scale)
                          pixelsHigh:qCeil(size.height() * scale) bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
                            isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0] autorelease];
        rep = [rep bitmapImageRepByRetaggingWithColorSpace:NSColorSpace.sRGBColorSpace];
        rep.size = size.toCGSize();

        _metrics.appearance = appearance;
        [_metrics cacheDisplayInRect:_metrics.bounds toBitmapImageRep:rep];

        _pane = QImage(rep.bitmapData, int(rep.pixelsWide), int(rep.pixelsHigh), int(rep.bytesPerRow),
                       QImage::Format_RGBA8888_Premultiplied).copy();
        _pane.setDevicePixelRatio(scale);
        _paneKey = key;
    }

    // only the bezel: it is open under the native bar and under the bar of the offscreen tab view, which is drawn
    // there without its selected title
    QPainterPath bars;
    bars.setFillRule(Qt::WindingFill);
    bars.addRect(layout.bar);
    bars.addRect(layout.offscreenBar);

    QPainterPath pane;
    pane.addRect(QRectF(QPointF(0, 0), QSizeF(size)));

    painter->save();
    painter->setClipPath(pane.subtracted(bars), Qt::IntersectClip);
    painter->drawImage(QPointF(0, 0), _pane);
    painter->restore();
}

void QCocoaTabWidgetPrivate::update(NSArray<NSString *> *titles, NSControlSize size)
{
    _metrics.controlSize = size;
    _metrics.font = fontOf(size);

    while (_metrics.numberOfTabViewItems > NSInteger(titles.count))
        [_metrics removeTabViewItem:_metrics.tabViewItems.lastObject];

    while (_metrics.numberOfTabViewItems < NSInteger(titles.count))
    {
        NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:nil];
        item.view = [[[NSView alloc] init] autorelease];
        [_metrics addTabViewItem:item];
        [item release];
    }

    for (NSUInteger i = 0; i < titles.count; ++i)
        _metrics.tabViewItems[i].label = titles[i];

    ++_generation;
}

QCocoaTabWidget::QCocoaTabWidget(QWidget *parent)
    : QTabWidget(parent)
{
#ifdef QCOCOATABWIDGET_NATIVE_BAR
    if (@available(macOS 26, *))
    {
        if (QCocoaAppearance::isLiquidGlass())
        {
            _native.reset(new QCocoaTabWidgetPrivate(this));

            // the style comes first, as setTabBar() lays the widget out, and the bar before any tab, as setTabBar()
            // doesn't take the tabs of the bar it replaces
            setStyle(_native->style);
            setTabBar(_native->bar);
            setFocusPolicy(Qt::NoFocus);

            _native->bar->sync();
        }
    }
#endif
}

QCocoaTabWidget::~QCocoaTabWidget()
{
    if (_native)
    {
        // the bar, a child widget, outlives this object, and the style must not outlive its use by the widget
        _native->bar->detach();
        setStyle(nullptr);
    }
}

bool QCocoaTabWidget::hasNativeTabBar() const
{
    return bool(_native);
}

void QCocoaTabWidget::changeEvent(QEvent *event)
{
    // the native bar takes the control size of the tab widget, and QTabWidget lays itself out again after that
    if (_native && event->type() == QEvent::MacSizeChange)
        _native->bar->sync();

    QTabWidget::changeEvent(event);
}
