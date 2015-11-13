#ifndef ApplicationUI_HPP_
#define ApplicationUI_HPP_

#include "AccountManager.h"
#include "DeviceUtils.h"
#include "NetworkProcessor.h"
#include "Persistance.h"
#include "QueryHelper.h"

#include <bb/system/CardDoneMessage>
#include <bb/system/LocaleHandler>

namespace safebrowse {

using namespace canadainc;

class ApplicationUI : public QObject
{
	Q_OBJECT

    Persistance m_persistance;
	AccountManager m_account;
	QueryHelper m_helper;
	NetworkProcessor m_network;
	QMap<QString, bool> m_extensions;
	bb::system::InvokeManager m_invokeManager;
	bb::system::InvokeRequest m_request;
	QObject* m_root;
	bb::system::LocaleHandler m_timeRender;
	DeviceUtils m_device;

    void init(QString const& qml);
    void processInvoke();

private slots:
    void childCardDone(bb::system::CardDoneMessage const& message=bb::system::CardDoneMessage());
    void invoked(bb::system::InvokeRequest const& request);
    void lazyInit();
    void onFileWritten();
    void onSaved();
    void progress(QVariant const& cookie, qint64 bytesSent, qint64 bytesTotal);
    void requestComplete(QVariant const& cookie, QByteArray const& data, bool error);

signals:
    void childCardFinished(QString const& message, QString const& cookie);
    void initialize();
    void lazyInitComplete();

public:
    ApplicationUI(bb::system::InvokeManager* im);
    virtual ~ApplicationUI();
    Q_INVOKABLE void addToHomeScreen(QString const& label, QUrl const& url, QString icon);
    Q_INVOKABLE void invokeSettingsApp();
    Q_INVOKABLE void invokeSystemApp(QUrl const& uri);
    Q_INVOKABLE QString renderStandardTime(QDateTime const& theTime);
    Q_INVOKABLE void backup(QObject* caller, QString const& callback, QString const& destination, bool restore);
};

} // salat

#endif /* ApplicationUI_HPP_ */
