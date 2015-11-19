#ifndef INVOKEHELPER_H_
#define INVOKEHELPER_H_

#include <bb/system/CardDoneMessage>
#include <bb/system/InvokeRequest>

#include "DeviceUtils.h"
#include "NetworkProcessor.h"

namespace bb {
    namespace system {
        class InvokeManager;
    }
}

namespace canadainc {
    class Persistance;
}

namespace safebrowse {

using namespace canadainc;
using namespace bb::system;

class InvokeHelper : public QObject
{
    Q_OBJECT

    bb::system::InvokeRequest m_request;
    QObject* m_root;
    Persistance* m_persist;
    DeviceUtils m_device;
    NetworkProcessor m_network;
    QMap<QString, bool> m_extensions;

    void invokeSystemApp(QUrl const& uri);

private slots:
    void childCardDone(bb::system::CardDoneMessage const& message=bb::system::CardDoneMessage());
    void onFileWritten();
    void progress(QVariant const& cookie, qint64 bytesSent, qint64 bytesTotal);
    void requestComplete(QVariant const& cookie, QByteArray const& data, bool error);

signals:
    void childCardFinished(QString const& message, QString const& cookie);

public:
    InvokeHelper(Persistance* persist);
    virtual ~InvokeHelper();

    void init(QString const& qmlDoc, QMap<QString, QObject*> context, QObject* parent);
    QString invoked(bb::system::InvokeRequest const& request);
    void process();
    void registerQmlTypes();
};

} /* namespace admin */

#endif /* INVOKEHELPER_H_ */
