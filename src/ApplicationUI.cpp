#include "precompiled.h"

#include "applicationui.hpp"
#include "AppLogFetcher.h" // needed for constants only
#include "CardUtils.h"
#include "InvocationUtils.h"
#include "IOUtils.h"
#include "Logger.h"
#include "QueryId.h"
#include "QueryHelper.h"
#include "TextUtils.h"
#include "ThreadUtils.h"

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

ApplicationUI::ApplicationUI(bb::system::InvokeManager* im) :
        m_persistance(im), m_account(&m_persistance),
        m_helper(&m_persistance), m_root(NULL)
{
    switch ( im->startupMode() )
    {
        case ApplicationStartupMode::LaunchApplication:
            init("main.qml");
            break;

        case ApplicationStartupMode::InvokeCard:
            connect( im, SIGNAL( cardPooled(bb::system::CardDoneMessage const&) ), QCoreApplication::instance(), SLOT( quit() ) );
            connect( im, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
            break;

        case ApplicationStartupMode::InvokeApplication:
            connect( im, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
            break;

        default:
            break;
    }

    connect( im, SIGNAL( childCardDone(bb::system::CardDoneMessage const&) ), this, SLOT( childCardDone(bb::system::CardDoneMessage const&) ) );
}


void ApplicationUI::init(QString const& qmlDoc)
{
    qmlRegisterUncreatableType<QueryId>("com.canadainc.data", 1, 0, "QueryId", "Can't instantiate");

    QMap<QString, QObject*> context;
    context.insert("security", &m_account);
    context.insert("helper", &m_helper);
    context.insert("network", &m_network);

    LOGGER("Instantiate" << qmlDoc);
    m_root = CardUtils::initAppropriate(qmlDoc, context, this);
    emit initialize();
}


void ApplicationUI::lazyInit()
{
    disconnect( this, SIGNAL( initialize() ), this, SLOT( lazyInit() ) ); // in case we get invoked again

    INIT_SETTING("keywordThreshold", 1);
    INIT_SETTING("mode", "passive");
    INIT_SETTING("home", "http://canadainc.org");

    m_helper.initDatabase();

    processInvoke();

    AppLogFetcher::create( &m_persistance, &ThreadUtils::compressFiles, this );
    DeviceUtils::registerTutorialTips(this);

    emit lazyInitComplete();
}


void ApplicationUI::processInvoke()
{
    QString target = m_request.target();

    if ( !target.isNull() )
    {
        connect( &m_network, SIGNAL( downloadProgress(QVariant const&, qint64, qint64) ), this, SLOT( progress(QVariant const&, qint64, qint64) ) );
        connect( &m_network, SIGNAL( requestComplete(QVariant const&, QByteArray const&, bool) ), this, SLOT( requestComplete(QVariant const&, QByteArray const&, bool) ) );

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


void ApplicationUI::childCardDone(bb::system::CardDoneMessage const& message)
{
    LOGGER( message.data() );
    emit childCardFinished( message.data(), message.reason().split("/").last() );

    if ( !message.data().isEmpty() ) {
        m_persistance.invokeManager()->sendCardDone(message);
    }
}


void ApplicationUI::requestComplete(QVariant const& cookie, QByteArray const& data, bool error)
{
    if (!error)
    {
        QFutureWatcher<QUrl>* qfw = new QFutureWatcher<QUrl>(this);
        connect( qfw, SIGNAL( finished() ), this, SLOT( onFileWritten() ) );

        QFuture<QUrl> future = QtConcurrent::run(writeFile, cookie, data);
        qfw->setFuture(future);
    }
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


ApplicationUI::~ApplicationUI()
{
}

} // salat
