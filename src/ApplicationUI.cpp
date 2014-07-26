#include "precompiled.h"

#include "applicationui.hpp"
#include "CardUtils.h"
#include "InvocationUtils.h"
#include "IOUtils.h"
#include "LocaleUtil.h"
#include "Logger.h"
#include "QueryId.h"
#include "QueryHelper.h"

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
    switch ( m_invokeManager.startupMode() )
    {
        case ApplicationStartupMode::LaunchApplication:
            //LogMonitor::create(UI_KEY, UI_LOG_FILE, this);
            init("main.qml");
            break;

        case ApplicationStartupMode::InvokeCard:
            //LogMonitor::create(CARD_KEY, CARD_LOG_FILE, this);
            connect( &m_invokeManager, SIGNAL( invoked(bb::system::InvokeRequest const&) ), this, SLOT( invoked(bb::system::InvokeRequest const&) ) );
            break;
        case ApplicationStartupMode::InvokeApplication:
            //LogMonitor::create(UI_KEY, UI_LOG_FILE, this);
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
    INIT_SETTING("mode", "passive");
    INIT_SETTING("home", "http://canadainc.org");

    connect( &m_network, SIGNAL( requestComplete(QVariant const&, QByteArray const&) ), this, SLOT( requestComplete(QVariant const&, QByteArray const&) ) );
    connect( &m_network, SIGNAL( downloadProgress(QVariant const&, qint64, qint64) ), this, SIGNAL( progress(QVariant const&, qint64, qint64) ) );

    m_helper.initDatabase();

    QString target = m_request.target();

    if ( !target.isNull() )
    {
        QUrl uri = m_request.uri();
        QString url = uri.toString();

        QString extension = url.toLower().split(".").last();

        if ( m_extensions.contains(extension) ) {
            m_network.doGet(url, url);
        } else {
            m_root->setProperty("target", uri);
        }
    } else {
        m_root->setProperty( "target", m_persistance.getValueFor("home") );
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
