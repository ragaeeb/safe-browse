#ifndef ApplicationUI_HPP_
#define ApplicationUI_HPP_

#include "AccountManager.h"
#include "customsqldatasource.h"
#include "LazySceneCover.h"
#include "LocaleUtil.h"
#include "Persistance.h"

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

	LocaleUtil m_locale;
	AccountManager m_account;
	LazySceneCover m_sceneCover;
	Persistance m_persistance;
	CustomSqlDataSource m_sql;
	bb::system::InvokeManager m_invokeManager;

    ApplicationUI(bb::cascades::Application *app);

private slots:
    void invoked(bb::system::InvokeRequest const& request);

public:
	static void create(bb::cascades::Application* app);
    virtual ~ApplicationUI();
    Q_INVOKABLE void invokeSettingsApp();
    Q_INVOKABLE void analyze(QString const& domain);
    Q_INVOKABLE void logBlocked(QString const& uri);
};

} // salat

#endif /* ApplicationUI_HPP_ */
