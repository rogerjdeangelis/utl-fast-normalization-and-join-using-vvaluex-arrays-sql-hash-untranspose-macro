Fast normalization and join using vvaluex arrays sql hash untranspose macro

  Six Solutions ( #5 and #6 are very elegant. #6 uses indirect addressing)

    1. Untranspose and Hash  (output in the order of the 'a' dataset - no reordering)

    2. Untranspose and SQL

    3. Datastep transpose and Hash (Draycut)
       https://communities.sas.com/t5/user/viewprofilepage/user-id/31304

    4. Datastep transpose and SQL (Draycut)
       https://communities.sas.com/t5/user/viewprofilepage/user-id/31304

    5. Datastep array and Merge (clever)
       FreelanceReinhard
       https://communities.sas.com/t5/user/viewprofilepage/user-id/32733

    6. Datastep vvaluex and Merge
       FreelanceReinhard
       https://communities.sas.com/t5/user/viewprofilepage/user-id/32733


github
https://tinyurl.com/y2eexggj
https://github.com/rogerjdeangelis/utl-fast-normalization-and-join-using-vvaluex-arrays-sql-hash-untranspose-macro

Art et all untranspose macro should be in yout toolkit. It is very fast
and flexible tool.

* AUTHORS: Arthur Tabachneck, Gerhard Svolba, Joe Matise and Matt Kastin
  art@analystfinder.com

macros (untranspose macro)
https://tinyurl.com/y9nfugth
https://github.com/rogerjdeangelis/utl-macros-used-in-many-of-rogerjdeangelis-repositories

SAS Forum
https://tinyurl.com/y6a7e4mz
https://communities.sas.com/t5/SAS-Programming/Selecting-columns-line-by-line-when-joining-tables/m-p/554578

*_                   _
(_)_ __  _ __  _   _| |_
| | '_ \| '_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
;

data a;
input Company_Name:$50. dealyear;
infile datalines dlm=',';
cards4;
Abcam plc,2000
Abeona Therapeutics Inc,1999
Abiomed Inc,2001
Acadia Healthcare,2002
;;;;
run;quit;

data b;
input Company_Name:$50. _1999 _2000 _2001 _2002;
infile datalines dlm=',';
cards4;
Abcam plc,6.648748,7.526305,14.21621,17.03757
Abeona Therapeutics Inc,602.3358,1363.622,933.9541,667.004
Abiomed Inc,8.457992,24.72086,20.06118,7.379444
Acadia Healthcare,4.092705,4.483808,1.457923,2.454762
;;;;
run;quit;

*           _
 _ __ _   _| | ___  ___
| '__| | | | |/ _ \/ __|
| |  | |_| | |  __/\__ \
|_|   \__,_|_|\___||___/

;


WORK.A total obs=4

  COMPANY_NAME               DEALYEAR

  Abcam plc                    2000
  Abeona Therapeutics Inc      1999
  Abiomed Inc                  2001
  Acadia Healthcare            2002


WORK.B total obs=4

  COMPANY_NAME                _1999       _2000     _2001      _2002

  Abcam plc                    6.649       7.53     14.216     17.038
  Abeona Therapeutics Inc    602.336    1363.62    933.954    667.004
  Abiomed Inc                  8.458      24.72     20.061      7.379
  Acadia Healthcare            4.093       4.48      1.458      2.455


 NORMALIZE B

 WORK.B_LONG total obs=16                        |  JOIN WITH A and SELECT ONLY THESE
                                                 |
  COMPANY_NAME               YEAR    STOCKPRICE  |  COMPANY_NAME               DEALYEAR    STOCKPRICE
                                                 |
  Abcam plc                  1999         6.65   |
  Abcam plc                  2000         7.53   |  Abcam plc                    2000          7.526
  Abcam plc                  2001        14.22   |
  Abcam plc                  2002        17.04   |
  Abeona Therapeutics Inc    1999       602.34   |  Abeona Therapeutics Inc      1999        602.336
  Abeona Therapeutics Inc    2000      1363.62   |
  Abeona Therapeutics Inc    2001       933.95   |
  Abeona Therapeutics Inc    2002       667.00   |
  Abiomed Inc                1999         8.46   |
  Abiomed Inc                2000        24.72   |
  Abiomed Inc                2001        20.06   |  Abiomed Inc                  2001         20.061
  Abiomed Inc                2002         7.38   |
  Acadia Healthcare          1999         4.09   |
  Acadia Healthcare          2000         4.48   |
  Acadia Healthcare          2001         1.46   |  Acadia Healthcare            2002          2.455
  Acadia Healthcare          2002         2.45   |

*            _               _
  ___  _   _| |_ _ __  _   _| |_
 / _ \| | | | __| '_ \| | | | __|
| (_) | |_| | |_| |_) | |_| | |_
 \___/ \__,_|\__| .__/ \__,_|\__|
                |_|
;

 WORK.WANT total obs=4

  COMPANY_NAME               DEALYEAR    STOCKPRICE

  Abcam plc                    2000          7.526
  Abeona Therapeutics Inc      1999        602.336
  Abiomed Inc                  2001         20.061
  Acadia Healthcare            2002          2.455

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __  ___
/ __|/ _ \| | | | | __| |/ _ \| '_ \/ __|
\__ \ (_) | | |_| | |_| | (_) | | | \__ \
|___/\___/|_|\__,_|\__|_|\___/|_| |_|___/

;

**************************
1. Untranspose and Hash  *
**************************


%untranspose(data=b, out=b_long(rename=_=stockprice), by=company_name, id=dealyear, var=_);

data want;

   if 0 then set b_long;

   if _N_ = 1 then do;
      declare hash h(dataset:'b_long');
      h.defineKey('Company_Name', 'dealyear');
      h.defineData('stockprice');
      h.defineDone();
   end;

   set a;

   rc=h.find();
   drop rc;
run;


**************************
1. Untranspose and SQL   *
**************************

%untranspose(data=b, out=b_long(rename=_=stockprice), by=company_name, id=dealyear, var=_);

proc sql;
   create table want as
   select a.*,
          b_long.stockprice
   from a, b_long
   where a.Company_Name=b_long.Company_Name
   and   a.dealyear=b_long.dealyear;
quit;


*******************************************
3. Datastep transpose and Hash (Draycut)  *
*******************************************

/* transpose b from wide to long */
data b_long(keep=Company_Name dealyear stockprice);
  set b;
  array y{*} _1999-_2002;
  do i=1 to dim(y);
     dealyear=input(compress(vname(y[i]), '_'), best.);
     stockprice=y[i];
     output;
  end;
run;

data want;

   if 0 then set b_long;

   if _N_ = 1 then do;
      declare hash h(dataset:'b_long');
      h.defineKey('Company_Name', 'dealyear');
      h.defineData('stockprice');
      h.defineDone();
   end;

   set a;

   rc=h.find();
   drop rc;
run;


*******************************************
4. Datastep transpose and SQL   (Draycut)  *
*******************************************

/* transpose b from wide to long */
data b_long(keep=Company_Name dealyear stockprice);
  set b;
  array y{*} _1999-_2002;
  do i=1 to dim(y);
     dealyear=input(compress(vname(y[i]), '_'), best.);
     stockprice=y[i];
     output;
  end;
run;

proc sql;
   create table want as
   select a.*,
          b_long.stockprice
   from a, b_long
   where a.Company_Name=b_long.Company_Name
   and   a.dealyear=b_long.dealyear;
quit;


******************************
5. Datastep  Merge (clever)  *
******************************

data want(drop=_:);

    merge a(in=a) b;
    by Company_Name;

    if a;

    array _[1999:2002] _:;
    stockprice=_[dealyear];

run;

********************************
6. Datastep vvaluex and Merge  *
********************************

data want(drop=_:);

    merge a(in=a) b;
    by Company_Name;

    if a;

    stockprice=input(vvaluex(cats('_',dealyear)),12.);

run;




