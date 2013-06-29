APP_NAME = SafeBrowse

INCLUDEPATH += ../src ../../canadainc/src/
CONFIG += qt warn_on cascades10
LIBS += -lbbsystem -lbbdata -lbbutilityi18n

CONFIG(release, debug|release) {
    DESTDIR = o.le-v7
    LIBS += -L../../canadainc/arm/o.le-v7 -lcanadainc -Bdynamic
}
CONFIG(debug, debug|release) {
    DESTDIR = o.le-v7-g
    LIBS += -L../../canadainc/arm/o.le-v7-g -lcanadainc -Bdynamic    
}

include(config.pri)