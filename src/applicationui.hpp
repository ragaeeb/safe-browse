#ifndef ApplicationUI_HPP_
#define ApplicationUI_HPP_

#include "AccountManager.h"
#include "customsqldatasource.h"
#include "LazySceneCover.h"
#include "LocaleUtil.h"
#include "Persistance.h"

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

    ApplicationUI(bb::cascades::Application *app);

public:
	static void create(bb::cascades::Application* app);
    virtual ~ApplicationUI();
    Q_INVOKABLE void invokeSettingsApp();
};

} // salat

#endif /* ApplicationUI_HPP_ */
