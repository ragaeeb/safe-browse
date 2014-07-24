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
    	InsertEntry,
    	DeleteEntry,
    	GetAll,
    	GetLogs,
    	InsertBlocked,
    	LogBlocked,
    	LogRequest,
    	LookupDomain,
    	Setup,
    	SettingUp,
    };
};

}

#endif /* QUERYID_H_ */
