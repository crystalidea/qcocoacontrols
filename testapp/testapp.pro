TEMPLATE = subdirs

SUBDIRS += app qcocoacontrols

qcocoacontrols.subdir = ../../qcocoacontrols

app.depends = qcocoacontrols
