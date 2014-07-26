APP_NAME = SafeBrowse

INCLUDEPATH += ../src ../../canadainc/src/
INCLUDEPATH += ../../quazip/src/
CONFIG += qt warn_on cascades10
LIBS += -lz
LIBS += -lbbsystem -lbbdata -lbbutilityi18n -lbbplatform -lbb -lbbdevice
QT += network

CONFIG(release, debug|release) {
    DESTDIR = o.le-v7
    LIBS += -L../../canadainc/arm/o.le-v7 -lcanadainc -Bdynamic
    LIBS += -Bstatic -L../../quazip/arm/o.le-v7 -lquazip -Bdynamic
}

CONFIG(debug, debug|release) {
    DESTDIR = o.le-v7-g
    LIBS += -L../../canadainc/arm/o.le-v7-g -lcanadainc -Bdynamic
    LIBS += -Bstatic -L../../quazip/arm/o.le-v7-g -lquazip -Bdynamic    
}

simulator {

CONFIG(release, debug|release)
{
    DESTDIR = o
    LIBS += -Bstatic -L../../canadainc/x86/o-g/ -lcanadainc -Bdynamic
    LIBS += -Bstatic -L../../quazip/x86/o-g -lquazip -Bdynamic     
}

}

include(config.pri)