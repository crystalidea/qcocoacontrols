TEMPLATE = lib
CONFIG += staticlib
QT += widgets

# TEMPLATE, CONFIG and QT are set BEFORE the include on purpose: the include
# evaluates scopes such as staticlib { } and !isEmpty(QT) as it is read.
#
# The author's tree keeps a fuller build include next to this repository; a
# plain GitHub checkout has only the copy shipped here. Pick whichever exists
# instead of asking the user to edit this line, and fail loudly rather than
# silently building with no configuration at all -- a failed include() is only
# a warning in qmake.

exists(../deploy_mac/qmake_mac.prj) {
    include (../deploy_mac/qmake_mac.prj)
} else {
    !include(qmake_mac.prj): error("cannot read qmake_mac.prj")
}

PRECOMPILED_HEADER = pch.h

HEADERS += qcocoawidget.h qcocoabutton.h qcocoasegmentedbutton.h qcocoaslider.h qcocoagradientbutton.h qcocoabox.h qcocoamessagebox.h qcocoaicon.h \
    qcocoabutton_p.h qcocoabuttonactionmenu.h qcocoapreferencesdialog.h qcocoapopover.h qcocoamenubaritem.h qcoregraphics.h pool.h

SOURCES += pch.cpp qcocoapreferencesdialog.cpp

OBJECTIVE_SOURCES += qcocoawidget.mm qcocoabutton.mm qcocoabutton_p.mm qcocoasegmentedbutton.mm qcocoaslider.mm qcocoagradientbutton.mm qcocoabox.mm \
    qcocoamessagebox.mm qcocoapreferencesdialog_mac.mm qcocoaicon.mm qcocoabuttonactionmenu.mm qcocoapopover.mm qcocoamenubaritem.mm qcoregraphics.mm pool.mm
