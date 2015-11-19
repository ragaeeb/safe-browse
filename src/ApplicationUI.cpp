#include "precompiled.h"

#include "applicationui.hpp"
#include "AppLogFetcher.h"
#include "Logger.h"
#include "TextUtils.h"
#include "ThreadUtils.h"

namespace safebrowse {

using namespace bb::cascades;
using namespace bb::system;
using namespace canadainc;

ApplicationUI::ApplicationUI(bb::system::InvokeManager* im) :
        m_persistance(im), m_account(&m_persistance),
        m_helper(&m_persistance), m_invoke(&m_persistance)
{
    switch ( im->startupMode() )
    {
        case ApplicationStartupMode::LaunchApplication:
            init("main.qml");
            break;

        case ApplicationStartupMode::InvokeCard:
            connect( im, SIGNAL( cardPooled(bb::system::CardDoneMessage const&) ), QCoreApplication::instance(), SLOT( quit() ) );
            break;

        default:
            break;
    }

    connect( im, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
}


void ApplicationUI::init(QString const& qmlDoc)
{
    QMap<QString, QObject*> context;
    context.insert("security", &m_account);
    context.insert("helper", &m_helper);

    m_invoke.init(qmlDoc, context, this);
    emit initialize();
}


void ApplicationUI::lazyInit()
{
    disconnect( this, SIGNAL( initialize() ), this, SLOT( lazyInit() ) ); // in case we get invoked again

    INIT_SETTING("keywordThreshold", 1);
    INIT_SETTING("mode", "passive");
    INIT_SETTING("home", "http://canadainc.org");

    m_helper.initDatabase();

    m_invoke.registerQmlTypes();
    m_invoke.process();

    AppLogFetcher::create( &m_persistance, &ThreadUtils::compressFiles, this );

    emit lazyInitComplete();
}


void ApplicationUI::invoked(bb::system::InvokeRequest const& request) {
    init( m_invoke.invoked(request) );
}


void ApplicationUI::invokeSettingsApp() {
    m_persistance.launchSettingsApp("childprotection");
}


void ApplicationUI::addToHomeScreen(QString const& label, QUrl const& url, QString icon)
{
    LOGGER(label << url << icon);

    QVariantMap data;
    data["url"] = url.toString();

    bool ok = false;
    QString ascii = QString::fromAscii( bb::PpsObject::encode(data, &ok) );
    LOGGER("ASCII" << ok << ascii);

    if (ok)
    {
        QString encoded = QString::fromAscii( QUrl::toPercentEncoding(ascii) );

        QString uri = QString("safebrowse:%1").arg(encoded);
        LOGGER("Uri saving:" << uri);
        bool added = bb::platform::HomeScreen().addShortcut( QUrl("asset:///images/icon_shortcut.png"), TextUtils::sanitize(label), uri);

        if (added) {
            m_persistance.showToast( tr("Successfully added %1 to the homescreen!").arg(label), "images/icon_shortcut.png" );
        } else {
            m_persistance.showToast( tr("Could not add %1 to the homescreen! Please file a bug report by swiping down from the top-bezel and choosing 'Bug Reports' and then clicking 'Submit Logs'. Please ensure the UI Logging is on and the problem is reproduced before you file the report."), "images/toast/error.png" );
#if defined(QT_NO_DEBUG)
        Report r(ReportType::BugReportAuto);
        r.params.insert(KEY_REPORT_NOTES, QString("[FailedAddHomeScreen1]: label,url=%1;%2").arg(label).arg( url.toString() ) );
        AppLogFetcher::getInstance()->submitReport(r);
#endif
        }
    } else {
        m_persistance.showToast( tr("Could not add %1 to the homescreen! Please file a bug report by swiping down from the top-bezel and choosing 'Bug Reports' and then clicking 'Submit Logs'. Please ensure the UI Logging is on and the problem is reproduced before you file the report."), "images/toast/error.png" );
#if defined(QT_NO_DEBUG)
        Report r(ReportType::BugReportAuto);
        r.params.insert(KEY_REPORT_NOTES, QString("[FailedAddHomeScreen2]: label,url=%1;%2").arg(label).arg( url.toString() ) );
        AppLogFetcher::getInstance()->submitReport(r);
#endif
    }
}


QString ApplicationUI::renderStandardTime(QDateTime const& theTime)
{
    static QString format = bb::utility::i18n::timeFormat(bb::utility::i18n::DateFormat::Short);
    return m_timeRender.locale().toString(theTime, format);
}


void ApplicationUI::backup(QObject* caller, QString const& callback, QString const& destination, bool restore)
{
    LOGGER(destination);

    BackupStruct bs(caller, callback, destination);

    QFutureWatcher<BackupStruct>* qfw = new QFutureWatcher<BackupStruct>(this);
    connect( qfw, SIGNAL( finished() ), this, SLOT( onSaved() ) );

    if (restore)
    {
        QFuture<BackupStruct> future = QtConcurrent::run(&ThreadUtils::performRestore, bs);
        qfw->setFuture(future);
    } else {
        QFuture<BackupStruct> future = QtConcurrent::run(&ThreadUtils::compressDatabase, bs);
        qfw->setFuture(future);
    }
}


void ApplicationUI::onSaved()
{
    QFutureWatcher<BackupStruct>* qfw = static_cast< QFutureWatcher<BackupStruct>* >( sender() );
    BackupStruct result = qfw->result();

    QObject* caller = result.caller;
    QByteArray qba = result.callback.toUtf8();
    const char* callback = qba.constData();

    qfw->deleteLater();
    QMetaObject::invokeMethod( caller, callback, Qt::QueuedConnection, Q_ARG(QVariant, result.destination) );
}


ApplicationUI::~ApplicationUI()
{
}

} // salat
