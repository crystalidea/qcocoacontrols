#include "pch.h"
#include "qcocoapopover_generic_dialog.h"

QPopoverDialog::QPopoverDialog(QWidget* contentWidget, QWidget* parent)
    : QDialog(parent, Qt::Popup | Qt::FramelessWindowHint)
    , m_content(contentWidget)
{
    // Allow alpha channel for smooth corners
    //setAttribute(Qt::WA_TranslucentBackground, true);

    setAttribute(Qt::WA_ShowWithoutActivating);
    //setFocusPolicy(Qt::NoFocus);

    // Optionally close automatically when user clicks outside
    // Qt::Popup does this automatically in many cases, but:
    // setWindowFlags(windowFlags() | Qt::Popup);

    // Insert your "main" widget into a layout
    QHBoxLayout* layout = new QHBoxLayout(this);
    layout->setContentsMargins(12, 12, 12, 12); // some margin from edges
    if (m_content) {
        m_content->setParent(this);
        layout->addWidget(m_content);
    }
    setLayout(layout);

    // add shadow
    auto shadow = new QGraphicsDropShadowEffect;
    shadow->setBlurRadius(16);
    shadow->setOffset(0, 3);
    setGraphicsEffect(shadow);

    resize(300, 150); // Arbitrary default size
}

void QPopoverDialog::paintEvent(QPaintEvent*) 
{
    // We’ll draw a white rounded rect with an arrow at the bottom center.

    // 1) Compute shape path
    QPainterPath path;
    const int radius = 8;   // corner radius
    const int arrowSize = 12;  // base width of the arrow
    const int arrowHeight = 10;  // height of the arrow
    const int w = width();
    const int h = height();

    // Start at top-left corner (with radius)
    path.moveTo(radius, 0);
    // Top line to top-right corner
    path.lineTo(w - radius, 0);
    // Top-right corner (arc)
    path.quadTo(w, 0, w, radius);
    // Right edge
    path.lineTo(w, h - radius - arrowHeight);
    // Bottom-right corner above arrow
    path.quadTo(w, h - arrowHeight, w - radius, h - arrowHeight);
    // Move to arrow right
    path.lineTo((w / 2) + (arrowSize / 2), h - arrowHeight);
    // Arrow tip
    path.lineTo(w / 2, h);
    // Move to arrow left
    path.lineTo((w / 2) - (arrowSize / 2), h - arrowHeight);
    // Bottom-left corner above arrow
    path.lineTo(radius, h - arrowHeight);
    path.quadTo(0, h - arrowHeight, 0, h - arrowHeight - radius);
    // Left edge
    path.lineTo(0, radius);
    // Top-left corner
    path.quadTo(0, 0, radius, 0);

    // 2) Clip window shape with setMask (or you can rely on alpha)
    //    This ensures the window is physically shaped like the popover
    QRegion maskRegion = QRegion(path.toFillPolygon().toPolygon());
    setMask(maskRegion);

    // 3) Draw the popover background
    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing);

    // Example fill: solid white with a light border
    painter.setPen(QPen(Qt::gray, 1.0));
    painter.setBrush(QColor(255, 255, 255));
    painter.drawPath(path);
}