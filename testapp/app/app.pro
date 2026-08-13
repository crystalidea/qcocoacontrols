# no shadow build please

TARGET = testapp
TEMPLATE = app

QT += core gui widgets

# QtMacExtras was removed in Qt 6; on Qt 5 it is still needed to resolve the
# QMacToolBar symbols used by qcocoapreferencesdialog_mac.mm

lessThan(QT_MAJOR_VERSION, 6): QT += macextras

# Must resolve to the SAME include the library used, otherwise BUILD_DIR differs
# and the -L / PRE_TARGETDEPS paths below point at a library that is not there.

exists(../../../deploy_mac/qmake_mac.prj) {
    include (../../../deploy_mac/qmake_mac.prj)
} else {
    !include(../../qmake_mac.prj): error("cannot read qmake_mac.prj")
}

SOURCES += main.cpp mainwindow.cpp
HEADERS  += mainwindow.h
FORMS    += mainwindow.ui

INCLUDEPATH += ../../../

LIBS += -L../../$$BUILD_DIR -lqcocoacontrols -ObjC
PRE_TARGETDEPS += ../../$$BUILD_DIR/libqcocoacontrols.a
