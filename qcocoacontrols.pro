# requires QMacExtras framework

include (../deploy_mac/qmake_mac.prj)

TEMPLATE = lib
CONFIG += staticlib
QT += widgets macextras
LIBS += -framework Foundation -framework Appkit
PRECOMPILED_HEADER = stdafx.h

INCLUDEPATH += $${MY_COMMON}

HEADERS += qcocoawidget.h qcocoabutton.h qcocoasegmentedbutton.h qcocoaslider.h qcocoagradientbutton.h qcocoabox.h qcocoamessagebox.h qcocoaicon.h \
    qcocoabutton_p.h \
    qcocoabuttonactionmenu.h \
    qcocoapreferencesdialog.h

SOURCES += qcocoapreferencesdialog.cpp

OBJECTIVE_SOURCES += qcocoawidget.mm qcocoabutton.mm qcocoabutton_p.mm qcocoasegmentedbutton.mm qcocoaslider.mm qcocoagradientbutton.mm qcocoabox.mm \
    qcocoamessagebox.mm qcocoapreferencesdialog_mac.mm qcocoaicon.mm qcocoabuttonactionmenu.mm

SOURCES += bigsurtoolbar.mm bigsurtoolbar.h
