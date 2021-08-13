# no shadow build please

include (../../qmake_mac.prj)

QT += core gui widgets macextras

TARGET = testapp
TEMPLATE = app
SOURCES += main.cpp mainwindow.cpp
HEADERS  += mainwindow.h
FORMS    += mainwindow.ui

INCLUDEPATH += ../../../

LIBS += -L../../$$BUILD_DIR -lqcocoacontrols -ObjC
PRE_TARGETDEPS += ../../$$BUILD_DIR/libqcocoacontrols.a
