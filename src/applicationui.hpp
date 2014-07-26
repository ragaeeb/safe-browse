#ifndef ApplicationUI_HPP_
#define ApplicationUI_HPP_

#include "AccountManager.h"
#include "LazySceneCover.h"
#include "NetworkProcessor.h"
#include "Persistance.h"
#include "QueryHelper.h"

#include <bb/system/InvokeManager>

namespace bb {
	namespace cascades {
		class Application;
	}
}

namespace safebrowse {

using namespace canadainc;

class ApplicationUI : public QObject
{
	Q_OBJECT

	AccountManager m_account;
	LazySceneCover m_sceneCover;
	Persistance m_persistance;
	QueryHelper m_helper;
	NetworkProcessor m_network;
	QMap<QString, bool> m_extensions;
	bb::system::InvokeManager m_invokeManager;
	bb::system::InvokeRequest m_request;
	QObject* m_root;

    ApplicationUI(bb::cascades::Application *app);
    void init(QString const& qml);

private slots:
    void invoked(bb::system::InvokeRequest const& request);
    void lazyInit();
    void onFileWritten();
    void progress(QVariant const& cookie, qint64 bytesSent, qint64 bytesTotal);
    void requestComplete(QVariant const& cookie, QByteArray const& data);

signals:
    void initialize();

public:
	static void create(bb::cascades::Application* app);
    virtual ~ApplicationUI();
    Q_INVOKABLE void invokeSettingsApp();
    Q_INVOKABLE void invokeSystemApp(QUrl const& uri);
    Q_INVOKABLE QString renderStandardTime(QDateTime const& theTime);
};

} // salat

#endif /* ApplicationUI_HPP_ */
