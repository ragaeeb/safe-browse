#ifndef ApplicationUI_HPP_
#define ApplicationUI_HPP_

#include "AccountManager.h"
#include "InvokeHelper.h"
#include "Persistance.h"
#include "QueryHelper.h"

#include <bb/system/LocaleHandler>
#include <bb/utility/i18n/CustomDateFormatter>

namespace safebrowse {

using namespace canadainc;

class ApplicationUI : public QObject
{
	Q_OBJECT

    Persistance m_persistance;
	AccountManager m_account;
	QueryHelper m_helper;
	bb::system::LocaleHandler m_timeRender;
	InvokeHelper m_invoke;
	bb::utility::i18n::CustomDateFormatter m_dateFormatter;

    void init(QString const& qml);
    void processInvoke();

private slots:
    void invoked(bb::system::InvokeRequest const& request);
    void lazyInit();
    void onSaved();

signals:
    void initialize();
    void lazyInitComplete();

public:
    ApplicationUI(bb::system::InvokeManager* im);
    virtual ~ApplicationUI();
    Q_INVOKABLE void addToHomeScreen(QString const& label, QUrl const& url, QString icon);
    Q_INVOKABLE void invokeSettingsApp();
    Q_INVOKABLE QString renderStandardTime(QDateTime const& theTime);
    Q_INVOKABLE void backup(QObject* caller, QString const& callback, QString const& destination, bool restore);
};

} // salat

#endif /* ApplicationUI_HPP_ */
