# change this
include (../deploy_mac/qmake_mac.prj)
# to
#include (qmake_mac.prj) # (when compiling from GitHub)

TEMPLATE = lib
CONFIG += staticlib
QT += widgets
PRECOMPILED_HEADER = pch.h

HEADERS += qcocoawidget.h qcocoabutton.h qcocoasegmentedbutton.h qcocoaslider.h qcocoagradientbutton.h qcocoabox.h qcocoamessagebox.h qcocoaicon.h \
    qcocoabutton_p.h qcocoabuttonactionmenu.h qcocoapreferencesdialog.h qcocoapopover.h qcocoamenubaritem.h qcoregraphics.h bigsurtoolbar.h

SOURCES += pch.cpp qcocoapreferencesdialog.cpp

OBJECTIVE_SOURCES += bigsurtoolbar.mm qcocoawidget.mm qcocoabutton.mm qcocoabutton_p.mm qcocoasegmentedbutton.mm qcocoaslider.mm qcocoagradientbutton.mm qcocoabox.mm \
    qcocoamessagebox.mm qcocoapreferencesdialog_mac.mm qcocoaicon.mm qcocoabuttonactionmenu.mm qcocoapopover.mm qcocoamenubaritem.mm qcoregraphics.mm

greaterThan(QT_MAJOR_VERSION, 5) {
    # Qt 6 builds
    HEADERS += pool.h
    OBJECTIVE_SOURCES += pool.mm
} else {
    # Qt 5 builds
    QT += macextras
}
