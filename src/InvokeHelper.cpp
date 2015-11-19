#include "precompiled.h"

#include "InvokeHelper.h"
#include "CardUtils.h"
#include "Logger.h"
#include "Persistance.h"
#include "QueryId.h"
#include "ThreadUtils.h"

#define HTTP_PROTOCOL "http"
#define HTTP_PREFIX "http://"
#define PROPERTY_TARGET_URL "target"
#define TARGET_SHORTCUT "com.canadainc.SafeBrowse.shortcut"
#define TARGET_SEARCH "com.canadainc.SafeBrowse.search"

namespace safebrowse {

using namespace bb::system;
using namespace canadainc;

InvokeHelper::InvokeHelper(Persistance* persist) :
        m_root(NULL), m_persist(persist)
{
    connect( persist->invokeManager(), SIGNAL( childCardDone(bb::system::CardDoneMessage const&) ), this, SLOT( childCardDone(bb::system::CardDoneMessage const&) ) );
}


void InvokeHelper::init(QString const& qmlDoc, QMap<QString, QObject*> context, QObject* parent)
{
    if (m_root) { // if scene already initialized, just process the invoke then
        process();
    } else {
        qmlRegisterUncreatableType<QueryId>("com.canadainc.data", 1, 0, "QueryId", "Can't instantiate");

        context.insert("network", &m_network);
        m_root = CardUtils::initAppropriate(qmlDoc, context, parent);
    }
}


QString InvokeHelper::invoked(bb::system::InvokeRequest const& request)
{
    QString target = request.target();

    LOGGER( request.action() << target << request.mimeType() << request.metadata() << request.uri().toString() << QString( request.data() ) );

    QMap<QString,QString> targetToQML;
    targetToQML[TARGET_SHORTCUT] = "main.qml";

    QString qml = targetToQML.value(target);

    if ( qml.isNull() ) {
        qml = "BrowserPane.qml";
    }

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

    return qml;
}


void InvokeHelper::process()
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

            if ( !url.startsWith(HTTP_PROTOCOL) ) {
                url = HTTP_PREFIX+url;
                uri = QUrl(url);
            }
        }

        QString extension = url.toLower().split(".").last();

        if ( m_extensions.contains(extension) ) {
            m_network.doGet(url, url);
        } else {
            m_root->setProperty(PROPERTY_TARGET_URL, uri);
        }
    } else {
        QString home = m_persist->getValueFor("home").toString();

        if ( !home.startsWith(HTTP_PROTOCOL) ) {
            home = HTTP_PREFIX+home;
        }

        m_root->setProperty(PROPERTY_TARGET_URL, home);
    }
}


void InvokeHelper::invokeSystemApp(QUrl const& uri)
{
    LOGGER(uri);

    bb::system::InvokeRequest request;
    request.setAction("bb.action.OPEN");
    request.setUri(uri);

    m_persist->invokeManager()->invoke(request);
}


void InvokeHelper::progress(QVariant const& cookie, qint64 bytesSent, qint64 bytesTotal)
{
    Q_UNUSED(cookie);

    m_root->setProperty("currentProgress", bytesSent);
    m_root->setProperty("totalProgress", bytesTotal);
}


void InvokeHelper::registerQmlTypes()
{
    DeviceUtils::registerTutorialTips(this);
}


void InvokeHelper::requestComplete(QVariant const& cookie, QByteArray const& data, bool error)
{
    if (!error)
    {
        QFutureWatcher<QUrl>* qfw = new QFutureWatcher<QUrl>(this);
        connect( qfw, SIGNAL( finished() ), this, SLOT( onFileWritten() ) );

        QFuture<QUrl> future = QtConcurrent::run(&ThreadUtils::writeFile, cookie, data);
        qfw->setFuture(future);
    }
}


void InvokeHelper::onFileWritten()
{
    QFutureWatcher<QUrl>* qfw = static_cast< QFutureWatcher<QUrl>* >( sender() );
    QUrl result = qfw->result();

    invokeSystemApp(result);

    sender()->deleteLater();
}


void InvokeHelper::childCardDone(bb::system::CardDoneMessage const& message)
{
    LOGGER( message.data() );
    emit childCardFinished( message.data(), message.reason().split("/").last() );

    if ( !message.data().isEmpty() ) {
        m_persist->invokeManager()->sendCardDone(message);
    }
}


InvokeHelper::~InvokeHelper()
{
}

} /* namespace admin */
