#-------------------------------------------------
#
# Project created by QtCreator 2014-09-15T15:22:55
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = testapp
TEMPLATE = app
SOURCES += main.cpp mainwindow.cpp
HEADERS  += mainwindow.h
FORMS    += mainwindow.ui

include(../cocoacontrols.pro)

