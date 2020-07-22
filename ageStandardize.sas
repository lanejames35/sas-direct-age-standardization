/****
 * Direct Age Standardization
 * 2020-07-22
 */
%macro ageStandardize(
    printHelp,
    data=,
    ageVariable=,
    numerator=,
    denominator=,
    standardPopulation=,
    standardPopulationAgeVariable=,
    byGroupVariable=,
    where=,
);

/* Help message */
%if %upcase(&printHelp) = HELP %then %goto help_msg;
/* Parameter validation */
%if %length(&data) = 0 %then %do;
    %put ====================;
    %put An value for data is required;
    %put Please check your macro call and try again.;
    %put Run %nrsrt(%ageStandardize(help)) for help;
    %put ====================;
    %goto exit;
%end;
%if %length(&ageVariable) = 0 %then %do;
    %put ====================;
    %put A value for ageVariable is required;
    %put Please check your macro call and try again.;
    %put Run %nrsrt(%ageStandardize(help)) for help;
    %put ====================;
    %goto exit;
%end;
%if %length(&numerator) = 0 %then %do;
    %put ====================;
    %put A value for numerator is required;
    %put Please check your macro call and try again.;
    %put Run %nrsrt(%ageStandardize(help)) for help;
    %put ====================;
    %goto exit;
%end;
%if %length(&denominator) = 0 %then %do;
    %put ====================;
    %put A value for denominator is required;
    %put Please check your macro call and try again.;
    %put Run %nrsrt(%ageStandardize(help)) for help;
    %put ====================;
    %goto exit;
%end;
%if %length(&standardPopulation) = 0 %then %do;
    %put ====================;
    %put A value for standardPopulation is required;
    %put Please check your macro call and try again.;
    %put Run %nrsrt(%ageStandardize(help)) for help;
    %put ====================;
    %goto exit;
%end;
%if %length(&standardPopulationAgeVariable) = 0 %then %do;
    %put ====================;
    %put A value for standardPopulationAgeVariable is required;
    %put Please check your macro call and try again.;
    %put Run %nrsrt(%ageStandardize(help)) for help;
    %put ====================;
    %goto exit;
%end;

/* Create standard population */
data canada2011;
input pop2011 age;
cards;
376321 0
379990 1
383179 2
383741 3
375833 4
366757 5
361038 6
363440 7
358621 8
360577 9
365198 10
376458 11
379838 12
391245 13
405425 14
426802 15
440145 16
446524 17
455872 18
469609 19
479650 20
484077 21
470052 22
458775 23
461800 24
471522 25
475052 26
474287 27
475287 28
473693 29
479377 30
472955 31
462922 32
455951 33
456750 34
457914 35
458413 36
448563 37
450150 38
458047 39
480129 40
478010 41
475541 42
473014 43
479224 44
506180 45
541424 46
557834 47
562501 48
551970 49
558958 50
548847 51
536639 52
529913 53
516903 54
501158 55
493948 56
473623 57
451080 58
433281 59
424456 60
414501 61
405624 62
404282 63
401580 64
344130 65
317981 66
306903 67
292908 68
271018 69
257990 70
240638 71
230156 72
218638 73
206400 74
200626 75
190737 76
180672 77
176879 78
170424 79
163436 80
152274 81
138753 82
129386 83
117291 84
107226 85
96193 86
85051 87
73870 88
64399 89
54015 90
43307 91
31444 92
24184 93
18966 94
13842 95
9962 96
7109 97
4974 98
3260 99
5268 100
;
run;

/* Scan age groups */
/* Extract age groupings and convert them to logic statements */
proc sql noprint;
   select distinct &age_var
        ,case
         when index(&age_var,'-')>1 then cat('between ',tranwrd(&age_var,'-',' and '))
         when index(&age_var,'<')=1 then substr(&age_var,index(&age_var,'<'))
         when index(&age_var,'+')>0 then cat(">=",substr(&age_var,1,index(&age_var,'+')-1))
         end as logic
   into :groupings separated by " ", :logic separated by "#"
   from &in;
quit;

/* Count the number of age groups to apply */
%local idx word countAgeGroups;
%let idx = 1;
%let word = %qscan(&groupings, &idx, "#");
%do %while(&word ne);
    %let idx = %eval(&idx + 1);
    %let word = %qscan(&groupings, &idx, "#");
%end;
%let countAgeGroups = %eval(&idx - 1);

/* Apply the groupings using the logic above */
proc sql noprint;
    create table standard as
    select case
        %do i=1 %to &countAgeGroups;
            %let result=%scan(&groupings,&i,%str( ));
            %let expression=%scan(&logic,&i,#);
            when age &expression then "&result"
        %end;
            else " "
            end as agecat,
            sum(&standardAgeVariable) as sum_&standardPopulationAgeVariable
            from &standardPopulation
            group by agecat
        ;
quit;

/* Merge and calculate */
proc sql noprint;
    select sum(sum_&standardPopulationAgeVariable)
    into :total_std
    from standard
    ;
quit;

data mergedStandard;
   merge step3(in=ina) standard(in=inb);
   by agecat;
   if ina and inb;

   w_i=sum_&standardPopulationAgeVariable/&total_std;

   ir_i=numer/denom;

   varpy_i=numer/(denom**2);
run;

data ASRcalculation;
    set mergedStandard(end=eof);
   /************************************
    * IRW=weighted incidence rate
    * VARPY=part of person-time variance
    * VARPYW=weighted person-time variance
    * SUMWI=sum of weights
    * CRDEN=crude denominator
    ***********************************/
   retain IRW VARPY VARPYW SUMWI CRNUM CRDEN;

    %if %length(&byGroupVariable) > 0 %then %do;
        by &byGroupVariable;
        if first.&geo_var then
        do;
            IRW=0;
            VARPYW=0;
            VARPY=0;
            SUMWI=0;
            CRNUM=0;
            CRDEN=0;
        end;

        IRW = IRW + (W_I * IR_I);
        SUMWI = SUMWI + W_I;
        VARPY = VARPY + ((W_I**2) * VARPY_I);
        CRNUM = CRNUM + numer;
        CRDEN = CRDEN + denom;

        if last.&geo_var then
        do;
        /********************************
            Crude incidence rate
        *******************************/
            CIR=CRNUM/CRDEN;

            VARPYW=VARPY/(SUMWI**2);

        /********************************
            95% CONFIDENCE LIMITS
        ********************************/
            LO95 = IRW - (1.96*SQRT(VARPYW));
            HI95 = IRW + (1.96*SQRT(VARPYW));
            output;
        end;
    %end;
    %else %do;
        IRW=0;
        VARPYW=0;
        VARPY=0;
        SUMWI=0;
        CRNUM=0;
        CRDEN=0;
        IRW = IRW + (W_I * IR_I);
        SUMWI = SUMWI + W_I;
        VARPY = VARPY + ((W_I**2) * VARPY_I);
        CRNUM = CRNUM + numer;
        CRDEN = CRDEN + denom;
        if eof then
        do;
        /********************************
            Crude incidence rate
        *******************************/
            CIR=CRNUM/CRDEN;

            VARPYW=VARPY/(SUMWI**2);

        /********************************
            95% CONFIDENCE LIMITS
        ********************************/
            LO95 = IRW - (1.96*SQRT(VARPYW));
            HI95 = IRW + (1.96*SQRT(VARPYW));
            output;
        end;
    %end;

    label CIR='Crude Incidence Rate'
        IRW='Age Standardized Incidence Rate'
        LO95='Lower 95% CI'
        HI95='Upper 95% CI'
    ;
run;
proc print noobs label;
    var &byGroupVariable CIR IRW LO95 HI95;
run;
%goto exit;
%help_msg:
    %put =================================;
    %put Direct Age Standardization;
    %put ;
    %put VERSION;
    %put 0.1.0;
    %put ;
    %put SYNTAX;
    %put %nrstr(%ageStandardize(<help ?>; <data=[Dataset Name]>, <ageVariable=[Column Name]>, <numerator=[Column Name], <demoninator=[Column Name]>, <standardPopulation=[Dataset Name]>, <standardPopulationAgeVariable=[Column Name]>, <scanAgeGroupsToMatch={YES | NO}>, <byGroupVariable=[Column Name]>, where=[Condition]));
    %put ;
    %put PARAMETERS;
    %put help: Use %nrstr(%ageStandardize(help)) to display this help message. Null otherwise.;
    %put data: Names the dataset used to perform the direct age standardization.;
    %put ageVariable: Names the column in "data" that contains the age data.;
    %put numerator: Names the column in "data" that conatins the number of people in the study population having a contidion of interest;
    %put denominator: Names the column in "data" that conatins the total number of people in the study population.;
    %put standardPopulation: Names the dataset used to weight the indicence rate.;
    %put standardPopulationAgeVariable: Names the column in "standardPopulation" that contains the age data.;
    %put byGroupVariable: Names the column used to split the data. Age standarization is calculated for each distinct level.;
    %put where: Filters the input data with the condition supplied.;
    %put ;
    %put ===================================;
%exit:
%mend;
