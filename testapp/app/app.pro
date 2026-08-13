# no shadow build please

include (../../qmake_mac.prj)

QT += core gui widgets

# QtMacExtras was removed in Qt 6; on Qt 5 it is still needed to resolve the
# QMacToolBar symbols used by qcocoapreferencesdialog_mac.mm

lessThan(QT_MAJOR_VERSION, 6): QT += macextras

TARGET = testapp
TEMPLATE = app
SOURCES += main.cpp mainwindow.cpp
HEADERS  += mainwindow.h
FORMS    += mainwindow.ui

INCLUDEPATH += ../../../

LIBS += -L../../$$BUILD_DIR -lqcocoacontrols -ObjC
PRE_TARGETDEPS += ../../$$BUILD_DIR/libqcocoacontrols.a
