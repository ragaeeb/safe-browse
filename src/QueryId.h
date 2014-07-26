#ifndef QUERYID_H_
#define QUERYID_H_

#include <qobjectdefs.h>

namespace safebrowse {

class QueryId
{
    Q_GADGET
    Q_ENUMS(Type)

public:
    enum Type {
    	ClearLogs,
    	ClearKeywords,
    	InsertEntry,
    	InsertKeyword,
    	DeleteEntry,
    	DeleteKeyword,
    	GetAll,
        GetKeywords,
    	GetLogs,
    	InsertBlocked,
    	LogBlocked,
        LogFailedLogin,
    	LogRequest,
    	LookupDomain,
    	LookupKeywords,
    	Setup,
    	SettingUp,
    };
};

}

#endif /* QUERYID_H_ */
