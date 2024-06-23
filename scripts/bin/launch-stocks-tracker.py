import datetime, holidays, os
from dateutil.tz import tzlocal

tz = tzlocal()
usHolidays = holidays.US()
def openToday(now = None):
    if not now:
        now = datetime.datetime.now(tz)
        openTime = datetime.time(hour = 9, minute = 30, second = 0)
        closeTime = datetime.time(hour = 16, minute = 0, second = 0)
        # If it is a holiday
        if now.strftime('%Y-%m-%d') in usHolidays:
            return False
        # If it is a weekend
        if now.date().weekday() > 4:
            return False
        return True


def closed():
     now = datetime.datetime.now(tz)
     closeTime = datetime.time(hour = 16, minute = 0, second = 0)
     # If before 0930 or after 1600
     if (now.time() > closeTime):
         return True
     return False
if (openToday() and not closed()):
    print("Open")
    os.system("i3-msg 'workspace 10; exec librewolf --new-window robinhood.com \
        && sleep 1 && firefox -new-tab app.webull.com/watch'")
