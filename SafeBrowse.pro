APP_NAME = SafeBrowse

INCLUDEPATH += ../src ../../canadainc/src/
CONFIG += qt warn_on cascades10
LIBS += -lbbsystem -lbbdata -lbbutilityi18n -lbbplatform -lbb
QT += network

CONFIG(release, debug|release) {
    DESTDIR = o.le-v7
    LIBS += -L../../canadainc/arm/o.le-v7 -lcanadainc -Bdynamic
}

CONFIG(debug, debug|release) {
    DESTDIR = o.le-v7-g
    LIBS += -L../../canadainc/arm/o.le-v7-g -lcanadainc -Bdynamic    
}

simulator {
CONFIG(release, debug|release) {
    DESTDIR = o
    LIBS += -Bstatic -L../../canadainc/x86/o-g/ -lcanadainc -Bdynamic     
}
CONFIG(debug, debug|release) {
    DESTDIR = o-g
    LIBS += -Bstatic -L../../canadainc/x86/o-g/ -lcanadainc -Bdynamic
}
}

include(config.pri)