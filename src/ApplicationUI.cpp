#include "precompiled.h"

#include "applicationui.hpp"
#include "CardUtils.h"
#include "InvocationUtils.h"
#include "IOUtils.h"
#include "LocaleUtil.h"
#include "Logger.h"
#include "LogMonitor.h"
#include "QueryId.h"
#include "QueryHelper.h"
#include "SafeBrowseCollector.h"
#include "TextUtils.h"

#define CARD_KEY "logCard"
#define TARGET_SHORTCUT "com.canadainc.SafeBrowse.shortcut"
#define TARGET_SEARCH "com.canadainc.SafeBrowse.search"

namespace {

QUrl writeFile(QVariant const& cookie, QByteArray const& data)
{
    QString uri = cookie.toString();
    QString fileName = uri.split("/").last();
    fileName = QString("%1/%2").arg( QDir::tempPath() ).arg(fileName);

    canadainc::IOUtils::writeFile(fileName, data);

    return QUrl::fromLocalFile(fileName);
}

}

namespace safebrowse {

using namespace bb::cascades;
using namespace bb::system;
using namespace canadainc;

ApplicationUI::ApplicationUI(bb::cascades::Application *app) :
        QObject(app), m_account(&m_persistance), m_sceneCover("Cover.qml"),
        m_helper(&m_persistance), m_root(NULL)
{
    INIT_SETTING(CARD_KEY, true);
    INIT_SETTING(UI_KEY, true);

    switch ( m_invokeManager.startupMode() )
    {
        case ApplicationStartupMode::LaunchApplication:
            LogMonitor::create(UI_KEY, UI_LOG_FILE, this);
            init("main.qml");
            break;

        case ApplicationStartupMode::InvokeCard:
            LogMonitor::create(CARD_KEY, CARD_LOG_FILE, this);
            connect( &m_invokeManager, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
            break;
        case ApplicationStartupMode::InvokeApplication:
            LogMonitor::create(UI_KEY, UI_LOG_FILE, this);
            connect( &m_invokeManager, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
            break;

        default:
            break;
    }
}


void ApplicationUI::init(QString const& qmlDoc)
{
    qmlRegisterUncreatableType<QueryId>("com.canadainc.data", 1, 0, "QueryId", "Can't instantiate");

    QMap<QString, QObject*> context;
    context.insert("security", &m_account);
    context.insert("helper", &m_helper);
    context.insert("app", this);
    context.insert("network", &m_network);

    LOGGER("Instantiate" << qmlDoc);
    m_root = CardUtils::initAppropriate(qmlDoc, context, this);
    emit initialize();
}


void ApplicationUI::lazyInit()
{
    INIT_SETTING("keywordThreshold", 1);
    INIT_SETTING("mode", "passive");
    INIT_SETTING("home", "http://canadainc.org");

    connect( &m_network, SIGNAL( downloadProgress(QVariant const&, qint64, qint64) ), this, SLOT( progress(QVariant const&, qint64, qint64) ) );
    connect( &m_network, SIGNAL( requestComplete(QVariant const&, QByteArray const&) ), this, SLOT( requestComplete(QVariant const&, QByteArray const&) ) );

    m_helper.initDatabase();

    QString target = m_request.target();

    if ( !target.isNull() )
    {
        QUrl uri = m_request.uri();
        QString url = uri.toString();

        if (target == TARGET_SHORTCUT)
        {
            url = m_request.uri().toString(QUrl::RemoveScheme);

            url = QUrl::fromPercentEncoding( url.toAscii() );
            bool ok = false;

            QVariantMap data = bb::PpsObject::decode( url.toAscii(), &ok );

            if (ok) {
                uri = data["url"].toUrl();
                url = uri.toString();
            }
        } else if (target == TARGET_SEARCH) {
            url = m_request.data();

            if ( !url.startsWith("http") ) {
                url = "http://"+url;
                uri = QUrl(url);
            }
        }

        QString extension = url.toLower().split(".").last();

        if ( m_extensions.contains(extension) ) {
            m_network.doGet(url, url);
        } else {
            m_root->setProperty("target", uri);
        }
    } else {
        QString home = m_persistance.getValueFor("home").toString();

        if ( !home.startsWith("http") ) {
            home = "http://"+home;
        }

        m_root->setProperty("target", home);
    }

    AppLogFetcher::create( new SafeBrowseCollector(), this );

    if ( !InvocationUtils::validateSharedFolderAccess( tr("Warning: It seems like the app does not have access to your Shared Folder. This permission is needed for the app to properly allow you to download files from the Internet and save them to your device. If you leave this permission off, some features may not work properly. Select OK to launch the Application Permissions screen where you can turn these settings on.") ) ) {}
}


void ApplicationUI::invoked(bb::system::InvokeRequest const& request)
{
    QString target = request.target();

    LOGGER( request.action() << target << request.mimeType() << request.metadata() << request.uri().toString() << QString( request.data() ) );

    QMap<QString,QString> targetToQML;

    QString qml = targetToQML.value(target);

    if ( qml.isNull() ) {
        qml = "BrowserPane.qml";
    }

    init(qml);

    m_request = request;

    m_extensions["amr"] = true;
    m_extensions["avi"] = true;
    m_extensions["doc"] = true;
    m_extensions["docx"] = true;
    m_extensions["gif"] = true;
    m_extensions["jpeg"] = true;
    m_extensions["jpg"] = true;
    m_extensions["m4a"] = true;
    m_extensions["mkv"] = true;
    m_extensions["mov"] = true;
    m_extensions["mp3"] = true;
    m_extensions["mp4"] = true;
    m_extensions["pdf"] = true;
    m_extensions["png"] = true;
    m_extensions["ppt"] = true;
    m_extensions["pptx"] = true;
    m_extensions["txt"] = true;
    m_extensions["xls"] = true;
    m_extensions["xlsx"] = true;
}


void ApplicationUI::requestComplete(QVariant const& cookie, QByteArray const& data)
{
    QFutureWatcher<QUrl>* qfw = new QFutureWatcher<QUrl>(this);
    connect( qfw, SIGNAL( finished() ), this, SLOT( onFileWritten() ) );

    QFuture<QUrl> future = QtConcurrent::run(writeFile, cookie, data);
    qfw->setFuture(future);
}


void ApplicationUI::progress(QVariant const& cookie, qint64 bytesSent, qint64 bytesTotal)
{
    Q_UNUSED(cookie);

    m_root->setProperty("currentProgress", bytesSent);
    m_root->setProperty("totalProgress", bytesTotal);
}


void ApplicationUI::onFileWritten()
{
    QFutureWatcher<QUrl>* qfw = static_cast< QFutureWatcher<QUrl>* >( sender() );
    QUrl result = qfw->result();

    invokeSystemApp(result);

    sender()->deleteLater();
}


void ApplicationUI::invokeSystemApp(QUrl const& uri)
{
    LOGGER(uri);

    bb::system::InvokeRequest request;
    request.setAction("bb.action.OPEN");
    request.setUri(uri);

    m_invokeManager.invoke(request);
}


void ApplicationUI::invokeSettingsApp() {
    InvocationUtils::launchSettingsApp("childprotection");
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
            m_persistance.showToast( tr("Successfully added %1 to the homescreen!").arg(label), "", "asset:///images/icon_shortcut.png" );
        } else {
            m_persistance.showToast( tr("Could not add %1 to the homescreen! Please file a bug report by swiping down from the top-bezel and choosing 'Bug Reports' and then clicking 'Submit Logs'. Please ensure the UI Logging is on and the problem is reproduced before you file the report."), "", "asset:///images/error.png" );
#if defined(QT_NO_DEBUG)
        AppLogFetcher::getInstance()->submitLogs( QString("[SafeBrowse]: label,url=%1;%2").arg(label).arg( url.toString() ) );
#endif
        }
    } else {
        m_persistance.showToast( tr("Could not add %1 to the homescreen! Please file a bug report by swiping down from the top-bezel and choosing 'Bug Reports' and then clicking 'Submit Logs'. Please ensure the UI Logging is on and the problem is reproduced before you file the report."), "", "asset:///images/error.png" );
#if defined(QT_NO_DEBUG)
        AppLogFetcher::getInstance()->submitLogs( QString("[SafeBrowse]: label,url=%1;%2").arg(label).arg( url.toString() ) );
#endif
    }
}


bool Persistance::clearCache()
{
    bool clear = showBlockingDialog( tr("Confirmation"), tr("Are you sure you want to clear the cache?") );

    if (clear) {
        QFutureWatcher<void>* qfw = new QFutureWatcher<void>(this);
        connect( qfw, SIGNAL( finished() ), this, SLOT( cacheCleared() ) );

        QFuture<void> future = QtConcurrent::run(&IOUtils::clearAllCache);
        qfw->setFuture(future);
    }

    return clear;
}


void Persistance::cacheCleared() {
    showToast( tr("Cache was successfully cleared!"), "file:///usr/share/icons/bb_action_delete.png" );
}



QString ApplicationUI::renderStandardTime(QDateTime const& theTime) {
    return LocaleUtil::renderStandardTime(theTime);
}


void ApplicationUI::create(Application* app) {
	new ApplicationUI(app);
}

ApplicationUI::~ApplicationUI()
{
}

} // salat
